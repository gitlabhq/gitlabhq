_This installation guide created for Debian/Ubuntu and properly tested._

_Checkout requirements before setup_


### IMPORTANT

Please make sure you have followed all the steps below before posting to the mailing list with installation and configuration questions.

Only create a GitHub Issue if you want a specific part of this installation guide updated.

Also read the [Read this before you submit an issue](https://github.com/gitlabhq/gitlabhq/wiki/Read-this-before-you-submit-an-issue) wiki page.

- - -

# Basic setup

The basic installation will provide you a GitLab setup with options:

1. ruby 1.9.3
2. mysql as main db
3. gitolite v3 fork by gitlab
4. nginx + unicorn

The installation consists of next steps:

1. Packages / dependencies
2. Ruby
3. Users
4. Gitolite
5. Mysql
6. GitLab.
7. Nginx 


# 1. Packages / dependencies

*Keep in mind that `sudo` is not installed on Debian by default. You should install it as root:*

    apt-get update && apt-get upgrade && apt-get install sudo

Now install the required packages:

    sudo apt-get update
    sudo apt-get upgrade

    sudo apt-get install -y wget curl build-essential checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev libreadline6-dev libc6-dev libssl-dev zlib1g-dev libicu-dev redis-server openssh-server git-core python2.7 libyaml-dev postfix

    sudo pip install pygments


# 2. Install Ruby

    wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p194.tar.gz
    tar xfvz ruby-1.9.3-p194.tar.gz
    cd ruby-1.9.3-p194
    ./configure
    make
    sudo make install

# 3. Users

Create user for git:

    sudo adduser \
      --system \
      --shell /bin/sh \
      --gecos 'git version control' \
      --group \
      --disabled-password \
      --home /home/git \
      git

Create user for GitLab:

    # ubuntu/debian
    sudo adduser --disabled-login --gecos 'gitlab system' gitlab

Add your users to groups:

    sudo usermod -a -G git gitlab
    sudo usermod -a -G gitlab git

Generate key:

    sudo -u gitlab -H ssh-keygen -q -N '' -t rsa -f /home/gitlab/.ssh/id_rsa


# 4. Gitolite

Clone GitLab's fork of the Gitolite source code:

    sudo -u git -H git clone -b gl-v304 https://github.com/gitlabhq/gitolite.git /home/git/gitolite

Setup:

    cd /home/git
    sudo -u git -H mkdir bin
    sudo -u git -H sh -c 'echo -e "PATH=\$PATH:/home/git/bin\nexport PATH" >> /home/git/.profile'
    sudo -u git -H sh -c 'gitolite/install -ln /home/git/bin'

    sudo cp /home/gitlab/.ssh/id_rsa.pub /home/git/gitlab.pub
    sudo chmod 0444 /home/git/gitlab.pub

    sudo -u git -H sh -c "PATH=/home/git/bin:$PATH; gitolite setup -pk /home/git/gitlab.pub"
 

Permissions:

    sudo chmod -R ug+rwXs /home/git/repositories/
    sudo chown -R git:git /home/git/repositories/

    # clone admin repo to add localhost to known_hosts
    # & be sure your user has access to gitolite
    sudo -u gitlab -H git clone git@localhost:gitolite-admin.git /tmp/gitolite-admin

    # if succeed  you can remove it
    sudo rm -rf /tmp/gitolite-admin

**IMPORTANT! If you can't clone `gitolite-admin` repository - DO NOT PROCEED WITH INSTALLATION**
Check the [Trouble Shooting Guide](https://github.com/gitlabhq/gitlab-public-wiki/wiki/Trouble-Shooting-Guide)
and ensure you have followed all of the above steps carefully.


# 5. Database

See doc/install/databases.md


# 6. GitLab

    cd /home/gitlab


#### Get source code

    # Get gitlab code. Use this for stable setup
    sudo -u gitlab -H git clone -b stable https://github.com/gitlabhq/gitlabhq.git gitlab

    # Skip this for stable setup.
    # Master branch (recent changes, less stable)
    sudo -u gitlab -H git clone -b master https://github.com/gitlabhq/gitlabhq.git gitlab


#### Copy configs
 
    cd gitlab

    # Rename config files
    #
    sudo -u gitlab -H cp config/gitlab.yml.example config/gitlab.yml

    # Copy unicorn config
    #
    sudo -u gitlab -H cp config/unicorn.rb.example config/unicorn.rb

#### Install gems

    cd /home/gitlab/gitlab

    sudo gem install charlock_holmes --version '0.6.9'
    sudo gem install bundler
    sudo -u gitlab -H bundle install --without development test postgres  --deployment

#### Configure git client

Gitlab needs to be able to commit and push changes to gitolite.
Git requires a username and email in order to be able to do that.

    sudo -u gitlab -H git config --global user.email "gitlab@localhost"
    sudo -u gitlab -H git config --global user.name "Gitlab"

#### Setup application

    sudo -u gitlab -H bundle exec rake gitlab:app:setup RAILS_ENV=production


#### Setup GitLab hooks

    sudo cp ./lib/hooks/post-receive /home/git/.gitolite/hooks/common/post-receive
    sudo chown git:git /home/git/.gitolite/hooks/common/post-receive

#### Check application status

Checking status:

    sudo -u gitlab -H bundle exec rake gitlab:app:status RAILS_ENV=production


    # OUTPUT EXAMPLE
    Starting diagnostic
    config/database.yml............exists
    config/gitlab.yml............exists
    /home/git/repositories/............exists
    /home/git/repositories/ is writable?............YES
    remote: Counting objects: 603, done.
    remote: Compressing objects: 100% (466/466), done.
    remote: Total 603 (delta 174), reused 0 (delta 0)
    Receiving objects: 100% (603/603), 53.29 KiB, done.
    Resolving deltas: 100% (174/174), done.
    Can clone gitolite-admin?............YES
    UMASK for .gitolite.rc is 0007? ............YES
    /home/git/share/gitolite/hooks/common/post-receive exists? ............YES

If you got all YES - congratulations! You can run a GitLab app.

#### init script

Create init script in /etc/init.d/gitlab:

    sudo wget https://raw.github.com/gitlabhq/gitlab-recipes/master/init.d/gitlab -P /etc/init.d/
    sudo chmod +x /etc/init.d/gitlab

GitLab autostart:

    sudo update-rc.d gitlab defaults 21

#### Now you should start GitLab application:

    sudo service gitlab start


# 7. Nginx

    # Install first
    sudo apt-get install nginx

    # Add GitLab to nginx sites & change with your host specific settings
    sudo wget https://raw.github.com/gitlabhq/gitlab-recipes/master/nginx/gitlab -P /etc/nginx/sites-available/
    sudo ln -s /etc/nginx/sites-available/gitlab /etc/nginx/sites-enabled/gitlab

    # Change **YOUR_SERVER_IP** and **YOUR_SERVER_FQDN**
    # to the IP address and fully-qualified domain name
    # of the host serving GitLab.
    sudo vim /etc/nginx/sites-enabled/gitlab

    # Restart nginx:
    sudo /etc/init.d/nginx restart


# Done!  Visit YOUR_SERVER for gitlab instance

You can login via web using admin generated with setup:

    admin@local.host
    5iveL!fe


- - -


# Advanced setup tips:

## Customizing Resque's Redis connection

If you'd like Resque to connect to a Redis server on a non-standard port or on
a different host, you can configure its connection string in the
**config/resque.yml** file:

    production: redis.example.com:6379

**Ok - we have a working application now. **
**But keep going - there are some things that should be done **
