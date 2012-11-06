#!/bin/bash

# This is a (for now unofficial) installer for gitlab intented for Debian or Debian based distro's like Ubuntu. 
# The installer will install: 
# 
# - GitLab
# - MySQL
# - Gitolite
# - Nginx
# - a mailserver if you choose so
# - a few thing like ruby, some gems, python stuff and so on
# 
# NOTE: the installer will upgrade your system without a promt! Because of this and other reasons like security we highly encourage you to run this on a dedicated VPS! Alway make backups of important files if there are any before using this installer!
#
# This installer is mainly based on https://github.com/gitlabhq/gitlabhq/blob/master/doc/install/installation.md
# 
# - additions are mainly:
#	* A 100% working GitLab installation after running this script (no maual steps needed).
#	* We help you with the mailserver (excpecially when choosing exim in combination with a smarthost setup). 
#		In our opninion this is the most reasenable setup because you use a other mailserver in stead of directly sending mail. 
#		This prevensts SPAM issues caused by spf misconfiguration and prevents open relay and such. 
#		A lot of people dont know how to configure a mailserver (wheter it is postfix or any other MTA). We do the job for you. 
#		All you need is a external mailserver (also Google is an option), a username and a password. Just like you mailclient uses.
#	* We also give the option not to install any mailserver if you are happy with your current setup.
# 	* not using path dependant commands, i.e. we dont want to cd in to directories where possible
# 	* some checks like filesystem and RAM free space + port bindings to port 80
# 	* making timeout higher for slow systems
#
# License: do whatever your want with this. Would be nice if you would report bugs to the place where you got this script or give some effort to contribute to it.


### settings (MOST PEOPLE DONT NEED TO EDIT ANYTHING!)
# DEBUG mode (gives info about what is run). To enable set to "yes"
debug=no
# minimum amount of diskpace we need in GB (used for warning)
minfreedisk=2
# minimum amount of free RAM in MB (used for warning)
minfreeram=300
# folder for downloading and making Ruby (needs some free diskspace and maybe exec permission?, so maybe you need to change this)
tmpfolder=/tmp


### functions
configure_exim () {

	echo -e "\n\nYou have chosen exim4. Please provide your e-mailadres so we can test the funcitonality later on:"	
	# your mailadress
	read yourmail 
	
	sudo apt-get install -y exim4

	# configure exim
	echo -e "\n\nIn the next step you will be asked some questions in orde to configure exim. \nWe suggest to use \"mail sent by smarthost; no local mail\". \nAfter this question only these two questions are really important:\n - \"IP address or host name of the outgoing smarthost\" \n   (fill in something like mail.youdomainname.com or smtp.gmail.com)\n - \"Root and postmaster mail recipient\". (fill in your own mailadress)\n\nThis way you can use a external mailserver just like your mailclient would do. \nIf you choose this, we will help you with the setup. \n(mailserver should support SSL though).\n\nIf you choose a different setup than smarthost you have to configure \nthe mailserver yourself after the install of GitLab. \n\nPress any key to continue..."
	read confirm4
	
	sudo dpkg-reconfigure exim4-config

	. /etc/exim4/update-exim4.conf.conf
	
	# setup smarthost
	if [ "${dc_smarthost}" != "" ]; then
	
		echo -e "\n\nYou have chosen a smarthost setup. We would like to help you configure this.\nPlease state the username for your mailserver:"		
		# username of your mailserver
		read smarthostusrname
		
		echo -e "\n\nPlease provide the password for you mailserver:"
		# password of your mailserver
		read -s smarthostpasswd

		echo "*:${smarthostusrname}:${smarthostpasswd}" > /etc/exim4/passwd.client
		sudo chown root:Debian-exim /etc/exim4/passwd.client && chmod 640 /etc/exim4/passwd.client
		echo "The mailfunctionality seems to work" | mail -r Gitserver -s "Gitserver testmail" ${yourmail}
		
		echo -e "\n\nYou schould receive a testmail within a minute. If not, please configure\nthe mailserver yourself after the installation of GitLab. \n\nPress any key to continue..."
		read confirm4

	fi
		
}


### set debug if wanted
if [ "${debug}" = "yes" ]; then

	set -x
	
fi

# check available diskspace
check=`df -B 1073741824 | grep "[[:space:]]/$" | sed 's/^[ ]*//' | sed 's/   */ /g' | cut -d' ' -f4`

if [ "${check}" -lt "${minfreedisk}" ]; then

	echo -e "We think theres not enough space left on your filesystem (where / is mounted). You need at least ${minfreedisk} GB on your filesystem:"
	df -h
	
	echo -e "are you sure you want to continue? (type 'yes' to continue)"
	read confirm
	
	if [ "${confirm}" != "yes" ]; then
	
		exit 1
		
	fi
	
fi

# check available memory
check=`free -m | grep "buffers/cache" | sed 's/   */ /g' | cut -d' ' -f4`

if [ "${check}" -lt "${minfreeram}" ]; then

	echo -e  "We think that there's not enough RAM left. You need at least ${minfreeram} MB of free RAM."
	free -m
	
	echo -e "are you sure you want to continue? (type 'yes' to continue)"
	read confirm2
	
	if [ "${confirm2}" != "yes" ]; then
	
		exit 1
		
	fi
	
fi

# check if we have apt
if [ ! -f "/usr/bin/apt-get" ]; then

	echo -e "You do not have aptitude! Is this a Debian bases distro at all (Debian or derivative like Ubuntu)? Exiting..."
	exit 1
	
fi


## start installer
# check sanity of argument, if no argument given use stable branch
while [ "${branch}" != "stable" ] && [ "${branch}" != "master" ]; do

	echo -e "Do you want a \"stable\" Gitlab setup or do you want to use the less stable \"master\" branch? (available options: [ stable / master ] )"
	read branch 
	
	if [ "${branch}" != "stable" ] && [ "${branch}" != "master" ]; then
	
		echo -e "You did not state \"stable\" or \"master\"!"
	
	fi
		
done


# update apt so we have newest repo info and clean old downloads and stuff
apt-get update && apt-get autoclean && apt-get autoremove


### install sudo if needed
if [ ! -f "/usr/bin/sudo" ]; then

	chk=`whoami | grep root`
	
	if [ "${chk}" = "" ]; then
	
		echo "Please login as root (or use 'su root')"
		exit 1
		
	else
	
		apt-get install -y sudo
		
	fi
	
fi

# do we have a mailer?
sudo apt-get install -y apt-show-versions
checkexim=`apt-show-versions | grep exim4`
checkpostfix=`apt-show-versions | grep postfix`
checksendmail=`apt-show-versions | grep sendmail`

if [ "${checkexim}" = "" ] && [ "${checkpostfix}" = "" ] && [ "${checksendmail}" = "" ]; then

	while [ "${choice}" != "0" ] && [ "${choice}" != "1" ] && [ "${choice}" != "2" ] && [ "${choice}" != "3" ]; do
		
		echo -e "you do not have a MTA (mail transfer agent) yet. You can choose between no mailer (0), Exim4 (1 - recommended), postfix (2) or sendmail (3). Please enter you choice:"
		read choice
		
		if [ "${choice}" != "0" ] && [ "${choice}" != "1" ] && [ "${choice}" != "2" ] && [ "${choice}" != "3" ]; then
		
			echo -e "You did not choose 0,1,2 or 3!"
			
		fi
		
	done
	
	if [ "${choice}" = "1" ]; then
		
		configure_exim
		
	elif  [ "${choice}" = "2" ]; then
		
		echo -e "\n\nYou have chosen postfix. At this time there is limited support. You should configure it yourself."	
		sudo apt-get install postfix
		
	elif  [ "${choice}" = "3" ]; then
		
		echo -e "\n\nYou have chosen sendmail. At this time there is limited support. You should configure it yourself."	
		sudo apt-get install sendmail
		
	else
	
		echo "You have chosen not to install a mailserver"
	
	fi
	
elif [ "${checkexim}" != "" ]; then

	
	while [ "${confirm3}" != "yes" ] && [ "${confirm3}" != "no" ]; do
	
		echo -e "\n\nYou have exim installed. Would you like us to help you configure it? (yes/no) (if exim works fine on this host answer NO)"	
		read confirm3
	
		if [ "${confirm3}" != "yes" ] && [ "${confirm3}" != "no" ]; then
		
			echo -e  "Please answer with yes or no"
			
		fi
		
	done
	
	if [ "${confirm3}" != "yes" ]; then
	
		configure_exim
		
	fi

elif [ "${checkpostfix}" != "" ]; then
	
	while [ "${confirm3}" != "yes" ] && [ "${confirm3}" != "no" ]; do
	
		echo -e "\n\nYou have already postfix installed, do you want to install exim instead including some help to get it working? (yes/no) (if postfix works fine on this host answer NO)"
		read confirm3
	
		if [ "${confirm3}" != "yes" ] && [ "${confirm3}" != "no" ]; then
		
			echo -e  "Please answer with yes or no"
			
		fi
		
	done
	
	sudo /etc/init.d/postfix stop
	sudo apt-get purge -y postfix*	
	
	configure_exim

elif [ "${checksendmail}" != "" ]; then

	while [ "${confirm3}" != "yes" ] && [ "${confirm3}" != "no" ]; do
	
		echo -e "\n\nYou have already sendmail installed, do you want to install exim instead including some help to get it working? (yes/no) (if sendmail works fine on this host answer NO)"
		read confirm3
	
		if [ "${confirm3}" != "yes" ] && [ "${confirm3}" != "no" ]; then
		
			echo -e  "Please answer with yes or no"
			
		fi
		
	done
	
	sudo /etc/init.d/sendmail stop
	sudo apt-get purge -y sendmail*
	
	configure_exim

fi


### upgrade and install the required packages:
echo -e "If you did not install MySQl before, you will need to provide a root password for it in the next step. Make shure you write it down! You will need to provide it to GitLab for a succesfull installation.\n\n Press any key to continue"
read confirm

sudo apt-get upgrade -y && sudo apt-get install -y nano mysql-server mysql-client libmysqlclient-dev wget curl gcc checkinstall libxml2-dev libxslt1-dev libcurl4-openssl-dev libreadline6-dev libc6-dev libssl-dev libmysql++-dev make build-essential zlib1g-dev libicu-dev redis-server openssh-server git-core python-dev python-pip libyaml-dev libpq-dev

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
if [ "${branch}" = "stable" ]; then

	sudo -H -u gitlab git clone -b stable https://github.com/gitlabhq/gitlabhq.git /home/gitlab/gitlab

# or use master branch (recent changes, less stable)
elif [ "${branch}" = "master" ]; then
	
	sudo -H -u gitlab git clone -b master https://github.com/gitlabhq/gitlabhq.git /home/gitlab/gitlab

fi

# copy configs
sudo -u gitlab cp /home/gitlab/gitlab/config/gitlab.yml.example /home/gitlab/gitlab/config/gitlab.yml
sudo -u gitlab cp /home/gitlab/gitlab/config/database.yml.mysql /home/gitlab/gitlab/config/database.yml
sudo -u gitlab cp /home/gitlab/gitlab/config/unicorn.rb.example /home/gitlab/gitlab/config/unicorn.rb

# edit gitlab.yml for correct e-mailsender
echo -e "What e-mailadres do you like to use for GitLab mails? (for account creation and notifications)"
read mailsender
sed -i "/from: / c from: ${mailsender}" /home/gitlab/gitlab/config/environments/production.rb

# install gems and bundle
sudo gem install charlock_holmes --version '0.6.8'
sudo gem install bundler
sudo -u gitlab -H sh -c "cd /home/gitlab/gitlab && bundle install --without development test sqlite postgres  --deployment"

# setup gitlab
sudo -u gitlab sh -c "cd /home/gitlab/gitlab && bundle exec rake gitlab:app:setup RAILS_ENV=production"

# setup GitLab hooks
sudo cp /home/gitlab/gitlab/lib/hooks/post-receive /home/git/.gitolite/hooks/common/post-receive
sudo chown git:git /home/git/.gitolite/hooks/common/post-receive

# if we have exim, patch the sendmailcommand not to use the -t option because this does not work. All the headers are available so we dont have to extract them anyway.
if [ -f "/usr/sbin/exim4" ]; then

	sed -i "/config.action_mailer.delivery_method = :sendmail/ c config.action_mailer.sendmail_settings = {\n     :location => '/usr/sbin/sendmail',\n     :arguments => '-i'\n}" /home/gitlab/gitlab/config/environments/production.rb
	
fi

# install init-script
sudo wget https://raw.github.com/gitlabhq/gitlab-recipes/master/init.d/gitlab -P /etc/init.d/
sudo chmod +x /etc/init.d/gitlab

# add to rc.d
sudo update-rc.d gitlab defaults 21

# make timout 300 because slow systems need more time when initiating gitlab for the first time
sed -i "/timeout / c timeout 300" /home/gitlab/gitlab/config/unicorn.rb

# start gitlab
/etc/init.d/gitlab start


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


### cleanup ruby download and make folder
rm -r ${tmpfolder}/${deploy}


### Post install message
echo -e "Installation is complete! Please go to the ip/port you just entered and use the following credentials to log in:\n\nusername: admin@local.host\npassword: 5iveL!fe\n\nMake sure to change these credential immedialty after logging in!"

exit 0