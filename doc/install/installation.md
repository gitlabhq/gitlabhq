This installation guide was created for Debian/Ubuntu and tested on it.

Please read doc/install/requirements.md for hardware andplatform requirements.


**Important Note**
The following steps have been known to work.
If you deviate from this guide, do it with caution and make sure you don't
violate any assumptions GitLab makes about its environment.
If you find a bug/error in this guide please an issue or pull request following
the contribution guide (see CONTRIBUTING.md).

- - -

# Overview

The GitLab installation consists of setting up th following components:

1. Packages / Dependencies
2. Ruby
3. System Users
4. Gitolite
5. Database
6. GitLab
7. Nginx


# 1. Packages / Dependencies

*Keep in mind that `sudo` is not installed on Debian by default. You should install it as root:*

    apt-get update && apt-get upgrade && apt-get install sudo

Make sure your system is up-to-date:

    sudo apt-get update
    sudo apt-get upgrade

Install the required packages:

    sudo apt-get install -y wget curl build-essential checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev libreadline6-dev libc6-dev libssl-dev zlib1g-dev libicu-dev redis-server openssh-server git-core python2.7 libyaml-dev postfix


# 2. Ruby

    wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p327.tar.gz
    tar xfvz ruby-1.9.3-p327.tar.gz
    cd ruby-1.9.3-p327
    ./configure
    make
    sudo make install


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
    sudo addmod -a -G git gitlab

    # Generate the SSH key
    sudo -u gitlab -H ssh-keygen -q -N '' -t rsa -f /home/gitlab/.ssh/id_rsa


# 4. Gitolite

Clone GitLab's fork of the Gitolite source code:

    sudo -u git -H git clone -b gl-v304 https://github.com/gitlabhq/gitolite.git /home/git/gitolite

Setup Gitolite with GitLab as its admin:

**Important Note**
GitLab assumes *full and unshared* control over this Gitolite installation.

    # Add Gitolite scripts to $PATH
    cd /home/git
    sudo -u git -H mkdir bin
    sudo -u git -H sh -c 'echo -e "PATH=\$PATH:/home/git/bin\nexport PATH" >> /home/git/.profile'
    sudo -u git -H sh -c 'gitolite/install -ln /home/git/bin'

    # Copy the gitlab user's (public) SSH key ...
    sudo cp /home/gitlab/.ssh/id_rsa.pub /home/git/gitlab.pub
    sudo chmod 0444 /home/git/gitlab.pub

    # ... and use it as the Gitolite admin key for setup
    sudo -u git -H sh -c "PATH=/home/git/bin:$PATH; gitolite setup -pk /home/git/gitlab.pub"

Fix the directory permissions for the repository:

    # Make sure the repositories dir is owned by git and it stays that way
    sudo chmod -R ug+rwXs /home/git/repositories/
    sudo chown -R git:git /home/git/repositories/

## Test if everything works so far

    # Clone the admin repo so SSH adds localhost to known_hosts ...
    # ... and to be sure your users have access to Gitolite
    sudo -u gitlab -H git clone git@localhost:gitolite-admin.git /tmp/gitolite-admin

    # If it succeeded without errors you can remove the cloned repo
    sudo rm -rf /tmp/gitolite-admin

**Impornant Note**
If you can't clone the `gitolite-admin` repository: **DO NOT PROCEED WITH INSTALLATION**
Check the [Trouble Shooting Guide](https://github.com/gitlabhq/gitlab-public-wiki/wiki/Trouble-Shooting-Guide)
and make sure you have followed all of the above steps carefully.


# 5. Database

See doc/install/databases.md


# 6. GitLab

    We'll install GitLab into the gitlab user's home directory
    cd /home/gitlab

## Clone the Source

    # Clone the latest stable release
    sudo -u gitlab -H git clone -b stable https://github.com/gitlabhq/gitlabhq.git gitlab

**Note***
You can change `stable` to `master` if you want the *bleeding edge* version, but
do so with caution!

## Configure it

    cd /home/gitlab/gitlab

    # Copy the example GitLab config
    sudo -u gitlab -H cp config/gitlab.yml.example config/gitlab.yml

    # Make sure to change "localhost" to the fully-qualified domain name of your
    # host serving GitLab where necessary
    sudo -u gitlab -H vim config/gitlab.yml

    # Copy the example Unicorn config
    sudo -u gitlab -H cp config/unicorn.rb.example config/unicorn.rb

**Important Note**
Make sure to edit both files to match your setup.

## Install Gems

    cd /home/gitlab/gitlab

    sudo gem install charlock_holmes --version '0.6.9'
    sudo gem install bundler
    sudo -u gitlab -H bundle install --deployment --without development test 

## Configure Git

GitLab needs to be able to commit and push changes to Gitolite. In order to do
that Git requires a username and email. (Please use the `email.from` address
for the email)

    sudo -u gitlab -H git config --global user.name "GitLab"
    sudo -u gitlab -H git config --global user.email "gitlab@localhost"

## Setup GitLab hooks

    sudo cp ./lib/hooks/post-receive /home/git/.gitolite/hooks/common/post-receive
    sudo chown git:git /home/git/.gitolite/hooks/common/post-receive

## Initialise Database and Activate Advanced Features

    sudo -u gitlab -H bundle exec rake gitlab:app:setup RAILS_ENV=production


## Check Application Status

Just to check we didn't miss anything.

    sudo -u gitlab -H bundle exec rake gitlab:app:status RAILS_ENV=production

```
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
```

If you are all green - congratulations! You run a GitLab now.
But there are still a few steps to go.


## Install Init Script

Download the init script (will be /etc/init.d/gitlab):

    sudo wget https://raw.github.com/gitlabhq/gitlab-recipes/master/init.d/gitlab -P /etc/init.d/
    sudo chmod +x /etc/init.d/gitlab

Make GitLab start on boot:

    sudo update-rc.d gitlab defaults 21


Start your GitLab instance:

    sudo service gitlab start


# 7. Nginx

## Installation
    sudo apt-get install nginx

## Site Configuration

Download an example site config:

    sudo wget https://raw.github.com/gitlabhq/gitlab-recipes/master/nginx/gitlab -P /etc/nginx/sites-available/
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

**Important Note**
Please go over to your profile page and immediately chage the password, so
nobody can access your GitLab by using this login information later on.

**Enjoy!**


- - -


# Advanced setup tips:

## Custom Redis connections

If you'd like Resque to connect to a Redis server on a non-standard port or on
a different host, you can configure its connection string via the
`config/resque.yml` file.

    # example
    production: redis.example.tld:6379
