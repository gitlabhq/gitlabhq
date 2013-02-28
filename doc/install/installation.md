This installation guide was created for Debian/Ubuntu and tested on it.

Please read [`doc/install/requirements.md`](./requirements.md) for hardware and platform requirements.


**Important Note:**
The following steps have been known to work.
If you deviate from this guide, do it with caution and make sure you don't
violate any assumptions GitLab makes about its environment.
For things like AWS installation scripts, init scripts or config files for
alternative web server have a look at the [`Advanced Setup
Tips`](./installation.md#advanced-setup-tips) section.


**Important Note:**
If you find a bug/error in this guide please submit an issue or pull request
following the [`contribution guide`](../../CONTRIBUTING.md).

- - -

# Overview

The GitLab installation consists of setting up the following components:

1. Packages / Dependencies
2. Ruby
3. System Users
4. GitLab shell
5. Database
6. GitLab
7. Nginx


# 1. Packages / Dependencies

`sudo` is not installed on Debian by default. Make sure your system is
up-to-date and install it.

    # run as root
    apt-get update
    apt-get upgrade
    apt-get install sudo

**Note:**
Vim is an editor that is used here whenever there are files that need to be
edited by hand. But, you can use any editor you like instead.

    # Install vim
    sudo apt-get install -y vim

Install the required packages:

    sudo apt-get install -y build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libreadline-dev libncurses5-dev libffi-dev curl git-core openssh-server redis-server postfix checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev

Make sure you have the right version of Python installed.

    # Install Python
    sudo apt-get install python

    # Make sure that Python is 2.5+ (3.x is not supported at the moment)
    python --version

    # If it's Python 3 you might need to install Python 2 separately
    sudo apt-get install python2.7

    # Make sure you can access Python via python2
    python2 --version

    # If you get a "command not found" error create a link to the python binary
    sudo ln -s /usr/bin/python /usr/bin/python2


# 2. Ruby

Download and compile it:

    mkdir /tmp/ruby && cd /tmp/ruby
    curl --progress http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p327.tar.gz | tar xz
    cd ruby-1.9.3-p327
    ./configure
    make
    sudo make install

Install the Bundler Gem:

    sudo gem install bundler


# 3. System Users

Create a `git` user for Gitlab:

    sudo adduser --disabled-login --gecos 'GitLab' git


# 4. GitLab shell

GitLab Shell is a ssh access and repository management software developed specially for GitLab.

    # Login as git 
    sudo su git

    # Go to home directory 
    cd /home/git

    # Clone gitlab shell
    git clone https://github.com/gitlabhq/gitlab-shell.git

    cd gitlab-shell
    cp config.yml.example config.yml

    # Edit config and replace gitlab_url 
    # with something like 'http://domain.com/'
    vim config.yml

    # Do setup
    ./bin/install 


# 5. Database

To setup the MySQL/PostgreSQL database and dependencies please see [`doc/install/databases.md`](./databases.md).


# 6. GitLab

    # We'll install GitLab into home directory of the user "git"
    cd /home/git

## Clone the Source

    # Clone GitLab repository
    sudo -u git -H git clone https://github.com/gitlabhq/gitlabhq.git gitlab

    # Go to gitlab dir 
    cd /home/git/gitlab
   
    # Checkout to stable release
    sudo -u git -H git checkout 5-0-stable

**Note:**
You can change `5-0-stable` to `master` if you want the *bleeding edge* version, but
do so with caution!

## Configure it

    cd /home/git/gitlab

    # Copy the example GitLab config
    sudo -u git -H cp config/gitlab.yml.example config/gitlab.yml

    # Make sure to change "localhost" to the fully-qualified domain name of your
    # host serving GitLab where necessary
    sudo -u git -H vim config/gitlab.yml

    # Make sure GitLab can write to the log/ and tmp/ directories
    sudo chown -R git log/
    sudo chown -R git tmp/
    sudo chmod -R u+rwX  log/
    sudo chmod -R u+rwX  tmp/

    # Create directory for satellites
    sudo -u git -H mkdir /home/git/gitlab-satellites

    # Create directory for pids and make sure GitLab can write to it
    sudo -u git -H mkdir tmp/pids/
    sudo chmod -R u+rwX  tmp/pids/
 
    # Copy the example Unicorn config
    sudo -u git -H cp config/unicorn.rb.example config/unicorn.rb

**Important Note:**
Make sure to edit both files to match your setup.

## Configure GitLab DB settings

    # Mysql
    sudo -u git cp config/database.yml.mysql config/database.yml

    # PostgreSQL
    sudo -u git cp config/database.yml.postgresql config/database.yml

Make sure to update username/password in config/database.yml.

## Install Gems

    cd /home/git/gitlab

    sudo gem install charlock_holmes --version '0.6.9'

    # For MySQL (note, the option says "without")
    sudo -u git -H bundle install --deployment --without development test postgres

    # Or for PostgreSQL
    sudo -u git -H bundle install --deployment --without development test mysql


## Initialise Database and Activate Advanced Features
    
    sudo -u git -H bundle exec rake db:setup RAILS_ENV=production
    sudo -u git -H bundle exec rake db:seed_fu RAILS_ENV=production
    sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production


## Install Init Script

Download the init script (will be /etc/init.d/gitlab):

    sudo curl --output /etc/init.d/gitlab https://raw.github.com/gitlabhq/gitlab-recipes/master/init.d/gitlab
    sudo chmod +x /etc/init.d/gitlab

Make GitLab start on boot:

    sudo update-rc.d gitlab defaults 21


## Check Application Status

Check if GitLab and its environment are configured correctly:

    sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production

To make sure you didn't miss anything run a more thorough check with:

    sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production

If all items are green, then congratulations on successfully installing GitLab!
However there are still a few steps left.

## Start Your GitLab Instance

    sudo service gitlab start
    # or
    sudo /etc/init.d/gitlab restart


# 7. Nginx

**Note:**
If you can't or don't want to use Nginx as your web server, have a look at the
[`Advanced Setup Tips`](./installation.md#advanced-setup-tips) section.

## Installation
    sudo apt-get install nginx

## Site Configuration

Download an example site config:

    sudo curl --output /etc/nginx/sites-available/gitlab https://raw.github.com/gitlabhq/gitlab-recipes/master/nginx/gitlab
    sudo ln -s /etc/nginx/sites-available/gitlab /etc/nginx/sites-enabled/gitlab

Make sure to edit the config file to match your setup:

    # Change **YOUR_SERVER_IP** and **YOUR_SERVER_FQDN**
    # to the IP address and fully-qualified domain name
    # of your host serving GitLab
    sudo vim /etc/nginx/sites-available/gitlab

## Restart

    sudo service nginx restart


# Done!

Visit YOUR_SERVER for your first GitLab login.
The setup has created an admin account for you. You can use it to log in:

    admin@local.host
    5iveL!fe

**Important Note:**
Please go over to your profile page and immediately chage the password, so
nobody can access your GitLab by using this login information later on.

**Enjoy!**


- - -


# Advanced Setup Tips

## Custom Redis Connection

If you'd like Resque to connect to a Redis server on a non-standard port or on
a different host, you can configure its connection string via the
`config/resque.yml` file.

    # example
    production: redis.example.tld:6379

## Custom SSH Connection

If you are running SSH on a non-standard port, you must change the gitlab user's SSH config.
    
    # Add to /home/git/.ssh/config
    host localhost          # Give your setup a name (here: override localhost)
        user git            # Your remote git user
        port 2222           # Your port number
        hostname 127.0.0.1; # Your server name or IP

You also need to change the corresponding options (e.g. ssh_user, ssh_host, admin_uri) in the `config\gitlab.yml` file.

## User-contributed Configurations

You can find things like  AWS installation scripts, init scripts or config files
for alternative web server in our [recipes collection](https://github.com/gitlabhq/gitlab-recipes/).
