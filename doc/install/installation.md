This installation guide was created for Debian/Ubuntu and tested on it.

Please read `doc/install/requirements.md` for hardware and platform requirements.


**Important Note:**
The following steps have been known to work.
If you deviate from this guide, do it with caution and make sure you don't
violate any assumptions GitLab makes about its environment.
For things like AWS installation scripts, init scripts or config files for
alternative web server have a look at the "Advanced Setup Tips" section.


**Important Note:**
If you find a bug/error in this guide please submit an issue or pull request
following the contribution guide (see `CONTRIBUTING.md`).

- - -

# Overview

The GitLab installation consists of setting up the following components:

1. Packages / Dependencies
2. Ruby
3. System Users
4. Gitolite
5. Database
6. GitLab
7. Nginx


# 1. Packages / Dependencies

`sudo` is not installed on Debian by default. If you don't have it you'll need
to install it first.

    # run as root
    apt-get update && apt-get upgrade && apt-get install sudo

Make sure your system is up-to-date:

    sudo apt-get update
    sudo apt-get upgrade

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

Create a user for Git and Gitolite:

    sudo adduser \
      --system \
      --shell /bin/sh \
      --gecos 'Git Version Control' \
      --group \
      --disabled-password \
      --home /home/git \
      git

Create a user for GitLab:

    sudo adduser --disabled-login --gecos 'GitLab' gitlab

    # Add it to the git group
    sudo usermod -a -G git gitlab

    # Generate the SSH key
    sudo -u gitlab -H ssh-keygen -q -N '' -t rsa -f /home/gitlab/.ssh/id_rsa


# 4. Gitolite

Clone GitLab's fork of the Gitolite source code:

    cd /home/git
    sudo -u git -H git clone -b gl-v320 https://github.com/gitlabhq/gitolite.git /home/git/gitolite

Setup Gitolite with GitLab as its admin:

**Important Note:**
GitLab assumes *full and unshared* control over this Gitolite installation.

    # Add Gitolite scripts to $PATH
    sudo -u git -H mkdir /home/git/bin
    sudo -u git -H sh -c 'printf "%b\n%b\n" "PATH=\$PATH:/home/git/bin" "export PATH" >> /home/git/.profile'
    sudo -u git -H sh -c 'gitolite/install -ln /home/git/bin'

    # Copy the gitlab user's (public) SSH key ...
    sudo cp /home/gitlab/.ssh/id_rsa.pub /home/git/gitlab.pub
    sudo chmod 0444 /home/git/gitlab.pub

    # ... and use it as the admin key for the Gitolite setup
    sudo -u git -H sh -c "PATH=/home/git/bin:$PATH; gitolite setup -pk /home/git/gitlab.pub"

Fix the directory permissions for the configuration directory:

    # Make sure the Gitolite config dir is owned by git
    sudo chmod 750 /home/git/.gitolite/
    sudo chown -R git:git /home/git/.gitolite/

Fix the directory permissions for the repositories:

    # Make sure the repositories dir is owned by git and it stays that way
    sudo chmod -R ug+rwX,o-rwx /home/git/repositories/
    sudo chown -R git:git /home/git/repositories/
    sudo -u git -H find /home/git/repositories -type d -print0 | sudo xargs -0 chmod g+s


## Add domains to list to the list of known hosts

    sudo -u gitlab -H ssh git@localhost
    sudo -u gitlab -H ssh git@YOUR_DOMAIN_NAME
    sudo -u gitlab -H ssh git@YOUR_GITOLITE_DOMAIN_NAME


## Test if everything works so far

    # Clone the admin repo so SSH adds localhost to known_hosts ...
    # ... and to be sure your users have access to Gitolite
    sudo -u gitlab -H git clone git@localhost:gitolite-admin.git /tmp/gitolite-admin

    # If it succeeded without errors you can remove the cloned repo
    sudo rm -rf /tmp/gitolite-admin

**Important Note:**
If you can't clone the `gitolite-admin` repository: **DO NOT PROCEED WITH INSTALLATION**!
Check the [Trouble Shooting Guide](https://github.com/gitlabhq/gitlab-public-wiki/wiki/Trouble-Shooting-Guide)
and make sure you have followed all of the above steps carefully.


# 5. Database

To setup the MySQL/PostgreSQL database and dependencies please see [`doc/install/databases.md`](./databases.md) .


# 6. GitLab

    # We'll install GitLab into home directory of the user "gitlab"
    cd /home/gitlab

## Clone the Source

    # Clone GitLab repository
    sudo -u gitlab -H git clone https://github.com/gitlabhq/gitlabhq.git gitlab

    # Go to gitlab dir 
    cd /home/gitlab/gitlab
   
    # Checkout to stable release
    sudo -u gitlab -H git checkout 4-2-stable

**Note:**
You can change `4-2-stable` to `master` if you want the *bleeding edge* version, but
do so with caution!

## Configure it

    cd /home/gitlab/gitlab

    # Copy the example GitLab config
    sudo -u gitlab -H cp config/gitlab.yml.example config/gitlab.yml

    # Make sure to change "localhost" to the fully-qualified domain name of your
    # host serving GitLab where necessary
    sudo -u gitlab -H vim config/gitlab.yml

    # Make sure GitLab can write to the log/ and tmp/ directories
    sudo chown -R gitlab log/
    sudo chown -R gitlab tmp/
    sudo chmod -R u+rwX  log/
    sudo chmod -R u+rwX  tmp/

    # Make directory for satellites
    sudo -u gitlab -H mkdir /home/gitlab/gitlab-satellites

    # Copy the example Unicorn config
    sudo -u gitlab -H cp config/unicorn.rb.example config/unicorn.rb

**Important Note:**
Make sure to edit both files to match your setup.

## Configure GitLab DB settings

    # Mysql
    sudo -u gitlab cp config/database.yml.mysql config/database.yml

    # PostgreSQL
    sudo -u gitlab cp config/database.yml.postgresql config/database.yml

Make sure to update username/password in config/database.yml.

## Install Gems

    cd /home/gitlab/gitlab

    sudo gem install charlock_holmes --version '0.6.9'

    # For MySQL (note, the option says "without")
    sudo -u gitlab -H bundle install --deployment --without development test postgres

    # Or for PostgreSQL
    sudo -u gitlab -H bundle install --deployment --without development test mysql

## Configure Git

GitLab needs to be able to commit and push changes to Gitolite. In order to do
that Git requires a username and email. (We recommend using the same address
used for the `email.from` setting in `config/gitlab.yml`)

    sudo -u gitlab -H git config --global user.name "GitLab"
    sudo -u gitlab -H git config --global user.email "gitlab@localhost"

## Setup GitLab Hooks

    sudo cp ./lib/hooks/post-receive /home/git/.gitolite/hooks/common/post-receive
    sudo chown git:git /home/git/.gitolite/hooks/common/post-receive

## Initialise Database and Activate Advanced Features

    sudo -u gitlab -H bundle exec rake gitlab:setup RAILS_ENV=production


## Install Init Script

Download the init script (will be /etc/init.d/gitlab):

    sudo curl --output /etc/init.d/gitlab https://raw.github.com/gitlabhq/gitlab-recipes/4-2-stable/init.d/gitlab
    sudo chmod +x /etc/init.d/gitlab

Make GitLab start on boot:

    sudo update-rc.d gitlab defaults 21


## Check Application Status

Check if GitLab and its environment is configured correctly:

    sudo -u gitlab -H bundle exec rake gitlab:env:info RAILS_ENV=production

To make sure you didn't miss anything run a more thorough check with:

    sudo -u gitlab -H bundle exec rake gitlab:check RAILS_ENV=production

If all items are green, then congratulations on successfully installing GitLab!
However there are still a few steps left.

## Start Your GitLab Instance

    sudo service gitlab start
    # or
    sudo /etc/init.d/gitlab restart


# 7. Nginx

**Note:**
If you can't or don't want to use Nginx as your web server, have a look at the
"Advanced Setup Tips" section.

## Installation
    sudo apt-get install nginx

## Site Configuration

Download an example site config:

    sudo curl --output /etc/nginx/sites-available/gitlab https://raw.github.com/gitlabhq/gitlab-recipes/4-2-stable/nginx/gitlab
    sudo ln -s /etc/nginx/sites-available/gitlab /etc/nginx/sites-enabled/gitlab

Make sure to edit the config file to match your setup:

    # Change **YOUR_SERVER_IP** and **YOUR_SERVER_FQDN**
    # to the IP address and fully-qualified domain name
    # of your host serving GitLab
    sudo vim /etc/nginx/sites-enabled/gitlab

## Restart

    sudo /etc/init.d/nginx restart


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

If you are running SSH on a non-standard port, you must change the gitlab user'S SSH config.
    
    # Add to /home/gitlab/.ssh/config
    host localhost          # Give your setup a name (here: override localhost)
        user git            # Your remote git user
        port 2222           # Your port number
        hostname 127.0.0.1; # Your server name or IP

You also need to change the corresponding options (e.g. ssh_user, ssh_host, admin_uri) in the `config\gitlab.yml` file.

## User-contributed Configurations

You can find things like  AWS installation scripts, init scripts or config files
for alternative web server in our [recipes collection](https://github.com/gitlabhq/gitlab-recipes/).
