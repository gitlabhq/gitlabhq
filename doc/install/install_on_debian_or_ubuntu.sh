#!/bin/bash

# this installer installs gitlab
# NOTE: the installer will upgrade your system without promt! Because of this and other reasons like security we highly encourage you to run this on a dedicated VPS! Alway make backups of important files if there are any!


### user settings
# DEBUG mode (gives info about what is run). To enable set to "yes"
debug=yes
# minimum amount of diskpace we need in GB
minfreedisk=1
# minimum amount of free RAM in MB
minfreeram=300
# folder for downloading and making Ruby (needs some free diskspace and maybe exec permission?, so maybe you need to change this)
tmpfolder=/tmp

### set debug if wanted
if [ "${debug}" = "yes" ]; then

	set -x
	
fi

### run some checks
# check if user has given us a good branch to use
die () {

	echo "ERROR: you need to provide exactly 11 arguments!!!"    
	echo "usage: $0 [ branch ] 'stable' or 'master' (master is less stable but newer branch)"
	exit 1

}

# check amount of arguments
[ "$#" -eq 1 ] || die 

# check sanity of argument
if [ "${1}" != "stable" ] || [ "${1}" != "master" ]; then

	echo "You must specify as argument: 'stable' or 'master'"
	exit 1
	
fi

# check available diskspace
check=`df -B 1073741824 | grep "[[:space:]]/$" | sed 's/^[ ]*//' | sed 's/   */ /g' | cut -d' ' -f4`

if [ "${check}" -lt "${minfreedisk}" ]; then

	echo We think theres not enough space left on your filesystem (where / is mounted). You need at least ${minfreedisk} GB:
	df -h
	
	echo are you sure you want to continue? (type 'yes' to continue)
	read confirm
	
	if [ "${confirm}" != "yes" ]; then
	
		exit 1
		
	fi
	
fi

# check available memory
check=`free -m | grep "buffers/cache" | sed 's/   */ /g' | cut -d' ' -f4`

if [ "${check}" -lt "${minfreeram}" ]; then

	echo -e  "We think that there's not enough RAM left. You need at least ${minfreeram} GB."
	free -m
	
	echo are you sure you want to continue? (type 'yes' to continue)
	read confirm
	
	if [ "${confirm}" != "yes" ]; then
	
		exit 1
		
	fi
	
fi

# check if we have apt
if [ ! -f "/usr/bin/apt-get" ]; then

	echo -e "You do not have aptitude! Is this a Debian bases distro at all (Debian or derivative like Ubuntu)? Exiting..."
	exit 1
	
fi


## start installer
# update apt so we have newest repo info
apt-get update 


### install sudo if needed
if [ ! -f "/usr/bin/sudo" ]; then

	chk=`whoami | grep root`
	
	if [ "${chk}" = "" ]; then
	
		echo "Please login as root (or use 'su root')"
		exit 1
		
	else
	
		apt-get install sudo
		
	fi
	
fi

### upgrade and install the required packages:
sudo apt-get upgrade -y && sudo apt-get install -y mysql-server mysql-client libmysqlclient-dev wget curl gcc checkinstall libxml2-dev libxslt1-dev libcurl4-openssl-dev libreadline6-dev libc6-dev libssl-dev libmysql++-dev make build-essential zlib1g-dev libicu-dev redis-server openssh-server git-core python-dev python-pip libyaml-dev libpq-dev

sudo pip install pygments


### install Ruby
# create foldername and folder in case we have diry make from earlier make
deploy=`date +%Y%m%d%H%M%S`
mkdir ${tmpfolder}/${deploy}
cd ${tmpfolder}/${deploy}

# install Ruby
wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p194.tar.gz
tar xfvz ruby-1.9.3-p194.tar.gz
cd ruby-1.9.3-p194
./configure && make && sudo make install


### usermanagement
# create user git
sudo adduser \
  --system \
  --shell /bin/sh \
  --gecos 'git version control' \
  --group \
  --disabled-password \
  --home /home/git \
  git

# create user gitlab
sudo adduser --disabled-login --gecos 'gitlab system' gitlab

# add user gitlab to group git & add user git to group gitlab
sudo usermod -a -G git gitlab && sudo usermod -a -G gitlab git

# generate key for user gitlab
sudo -H -u gitlab ssh-keygen -q -N '' -t rsa -f /home/gitlab/.ssh/id_rsa

### clone and install gitolite repo
sudo -H -u git git clone -b gl-v304 https://github.com/gitlabhq/gitolite.git /home/git/gitolite

# create bin directory
sudo -u git -H mkdir /home/git/bin

# add /home/git/bin to path of user git
sudo -u git sh -c 'echo -e "PATH=\$PATH:/home/git/bin\nexport PATH" >> /home/git/.profile'

# install gitolite
sudo -u git sh -c '/home/git/gitolite/install -ln /home/git/bin'

# move key and edit permissions
sudo cp /home/gitlab/.ssh/id_rsa.pub /home/git/gitlab.pub && sudo chmod 0444 /home/git/gitlab.pub

# tell user git to use key in new location
sudo -u git -H sh -c "PATH=/home/git/bin:$PATH; gitolite setup -pk /home/git/gitlab.pub"

# set permissions for repositories folder
sudo chmod -R g+rwX /home/git/repositories/ && sudo chown -R git:git /home/git/repositories/

# add localhost to known_hosts so we dont have to accept the key during install
ssh-keyscan -t rsa localhost >> /home/gitlab/.ssh/known_hosts


### install gitlab
# clone gitlab repo for stable setup
if [ "${1}" = "stable" ]; then

	sudo -H -u gitlab git clone -b stable https://github.com/gitlabhq/gitlabhq.git /home/gitlab/gitlab

# or use master branch (recent changes, less stable)
elif [ "${1}" = "master" ]; then
	
	sudo -H -u gitlab git clone -b master https://github.com/gitlabhq/gitlabhq.git /home/gitlab/gitlab

fi

# copy configs
sudo -u gitlab cp /home/gitlab/gitlab/config/gitlab.yml.example /home/gitlab/gitlab/config/gitlab.yml
sudo -u gitlab cp /home/gitlab/gitlab/config/database.yml.mysql /home/gitlab/gitlab/config/database.yml
sudo -u gitlab cp /home/gitlab/gitlab/config/unicorn.rb.example /home/gitlab/gitlab/config/unicorn.rb

# install gems and bundle
sudo gem install charlock_holmes --version '0.6.8'
sudo gem install bundler
sudo -u gitlab -H sh -c "cd /home/gitlab/gitlab && bundle install --without development test sqlite postgres  --deployment"

# setup gitlab
sudo -u gitlab sh -c "cd /home/gitlab/gitlab && bundle exec rake gitlab:app:setup RAILS_ENV=production"

# setup GitLab hooks
sudo cp /home/gitlab/gitlab/lib/hooks/post-receive /home/git/.gitolite/hooks/common/post-receive
sudo chown git:git /home/git/.gitolite/hooks/common/post-receive


# install init-script
sudo wget https://raw.github.com/gitlabhq/gitlab-recipes/master/init.d/gitlab -P /etc/init.d/
sudo chmod +x /etc/init.d/gitlab

# add to rc.d
sudo update-rc.d gitlab defaults 21

# make timout 300 because slow systems need more time when initiating gitlab for the first time
sed -i "/timeout / c timeout 300" /home/gitlab/gitlab/config/unicorn.rb

# start gitlab
sudo service gitlab start


### install Nginx
sudo apt-get install nginx

# Add GitLab to nginx sites & change with your host specific settings
sudo wget https://raw.github.com/gitlabhq/gitlab-recipes/master/nginx/gitlab -P /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/gitlab /etc/nginx/sites-enabled/gitlab

# check if a precess is using port 80
check=`netstat -natp | grep :80`
if [ "${check}" !=  "" ]; then

	echo -e "make sure you do not use port 80, because another process is using this port:\n${check}\n\nWe will remove the default nginx host for you, but make sure to change the port in the next step! Press Enter to continue..."
	read confirm
	
	rm /etc/nginx/sites-enabled/default
	
fi

# Change **YOUR_SERVER_IP**, port and **YOUR_SERVER_FQDN**
# to the IP address and fully-qualified domain name
sudo editor /etc/nginx/sites-enabled/gitlab

# Restart nginx:
sudo /etc/init.d/nginx restart


### cleanup
rm -r ${tmpfolder}/${deploy}


### Post install message
echo -e "Installation is complete! Please go to the ip/port you just entered and use the following credentials to log in:\n\nusername: admin@local.host\npassword: 5iveL!fe\n\nMake sure to change these credential immedialty after logging in!"

exit 0
