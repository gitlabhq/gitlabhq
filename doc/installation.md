## Platform requirements:

**The project is designed for the Linux operating system.**

It may work on FreeBSD and Mac OS, but we don't test our application for these systems and can't guarantee stability and full functionality.

We officially support (recent versions of) these Linux distributions:

- Ubuntu Linux
- Debian/GNU Linux

It should work on:

- Fedora
- CentOs
- RedHat

You might have some luck using these, but no guarantees:

 - MacOS X
 - FreeBSD

GitLab does **not** run on Windows and we have no plans of making GitLab compatible.

## This installation guide created for Debian/Ubuntu and properly tested.

The installation consists of 6 steps:

1. Install packages / dependencies
2. Install ruby
3. Install Gitolite
4. Install and configure GitLab.
5. Start the web front-end
6. Start a Resque worker (for background processing)

### IMPORTANT

Please make sure you have followed all the steps below before posting to the mailing list with installation and configuration questions.

Only create a GitHub Issue if you want a specific part of this installation guide updated.

Also read the [Read this before you submit an issue](https://github.com/gitlabhq/gitlabhq/wiki/Read-this-before-you-submit-an-issue) wiki page.

> - - -
> The first 3 steps of this guide can be easily skipped by executing an install script:
>
>     # Install curl and sudo
>     apt-get install curl sudo
>
>     # 3 steps in 1 command :)
>     curl https://raw.github.com/gitlabhq/gitlab-recipes/master/install/debian_ubuntu.sh | sh
>
> Now you can go to [Step 4](#4-install-gitlab-and-configuration-check-status-configuration)
>
> Or if you are installing on Amazon Web Services using Ubuntu 12.04 you can do all steps (1 to 6) at once with:
>
>     curl https://raw.github.com/gitlabhq/gitlab-recipes/master/install/debian_ubuntu_aws.sh | sh
>
> for more detailed instructions read the HOWTO section of [the script](https://github.com/gitlabhq/gitlab-recipes/blob/master/install/debian_ubuntu_aws.sh)
> - - -

# 1. Install packages

*Keep in mind that `sudo` is not installed on Debian by default. You should install it as root:*

    apt-get update && apt-get upgrade && apt-get install sudo

Now install the required packages:

    sudo apt-get update
    sudo apt-get upgrade

    sudo apt-get install -y wget curl gcc checkinstall libxml2-dev libxslt-dev sqlite3 libsqlite3-dev libcurl4-openssl-dev libreadline6-dev libc6-dev libssl-dev libmysql++-dev make build-essential zlib1g-dev libicu-dev redis-server openssh-server git-core python-dev python-pip libyaml-dev postfix

    # If you want to use MySQL:
    sudo apt-get install -y mysql-server mysql-client libmysqlclient-dev

# 2. Install Ruby

    wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p194.tar.gz
    tar xfvz ruby-1.9.3-p194.tar.gz
    cd ruby-1.9.3-p194
    ./configure
    make
    sudo make install

# 3. Install Gitolite

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

Add your user to the `git` group:

    sudo usermod -a -G git gitlab

Generate key:

    sudo -H -u gitlab ssh-keygen -q -N '' -t rsa -f /home/gitlab/.ssh/id_rsa

Clone GitLab's fork of the Gitolite source code:

    sudo -H -u git git clone -b gl-v304 https://github.com/gitlabhq/gitolite.git /home/git/gitolite

Setup:

    cd /home/git
    sudo -u git -H mkdir bin
    sudo -u git sh -c 'echo -e "PATH=\$PATH:/home/git/bin\nexport PATH" >> /home/git/.profile'
    sudo -u git sh -c 'gitolite/install -ln /home/git/bin'

    sudo cp /home/gitlab/.ssh/id_rsa.pub /home/git/gitlab.pub
    sudo chmod 0444 /home/git/gitlab.pub

    sudo -u git -H sh -c "PATH=/home/git/bin:$PATH; gitolite setup -pk /home/git/gitlab.pub"
    sudo -u git -H sed -i 's/0077/0007/g' /home/git/.gitolite.rc

Permissions:

    sudo chmod -R g+rwX /home/git/repositories/
    sudo chown -R git:git /home/git/repositories/

#### CHECK: Logout & login again to apply git group to your user

    # clone admin repo to add localhost to known_hosts
    # & be sure your user has access to gitolite
    sudo -u gitlab -H git clone git@localhost:gitolite-admin.git /tmp/gitolite-admin

    # if succeed  you can remove it
    sudo rm -rf /tmp/gitolite-admin

**IMPORTANT! If you can't clone `gitolite-admin` repository - DO NOT PROCEED WITH INSTALLATION**
Check the [Trouble Shooting Guide](https://github.com/gitlabhq/gitlab-public-wiki/wiki/Trouble-Shooting-Guide)
and ensure you have followed all of the above steps carefully.

# 4. Clone GitLab source and install prerequisites

    sudo gem install charlock_holmes --version '0.6.8'
    sudo pip install pygments
    sudo gem install bundler
    cd /home/gitlab

    # Get gitlab code. Use this for stable setup
    sudo -H -u gitlab git clone -b stable https://github.com/gitlabhq/gitlabhq.git gitlab

    # Skip this for stable setup.
    # Master branch (recent changes, less stable)
    sudo -H -u gitlab git clone -b master https://github.com/gitlabhq/gitlabhq.git gitlab

    cd gitlab

    # Rename config files
    sudo -u gitlab cp config/gitlab.yml.example config/gitlab.yml

#### Select the database you want to use

    # SQLite
    sudo -u gitlab cp config/database.yml.sqlite config/database.yml

    # Or
    # Mysql
    # Install MySQL as directed in Step #1

    # Login to MySQL
    $ mysql -u root -p

    # Create the GitLab production database
    mysql> CREATE DATABASE IF NOT EXISTS `gitlabhq_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;

    # Create the MySQL User change $password to a real password
    mysql> CREATE USER 'gitlab'@'localhost' IDENTIFIED BY '$password';

    # Grant proper permissions to the MySQL User
    mysql> GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON `gitlabhq_production`.* TO 'gitlab'@'localhost';

    # Exit MySQL Server and copy the example config, make sure to update username/password in config/database.yml
    sudo -u gitlab cp config/database.yml.example config/database.yml

#### Install gems

    sudo -u gitlab -H bundle install --without development test --deployment

#### Setup database

    sudo -u gitlab bundle exec rake gitlab:app:setup RAILS_ENV=production

#### Setup GitLab hooks

    sudo cp ./lib/hooks/post-receive /home/git/.gitolite/hooks/common/post-receive
    sudo chown git:git /home/git/.gitolite/hooks/common/post-receive

#### Check application status

Checking status:

    sudo -u gitlab bundle exec rake gitlab:app:status RAILS_ENV=production


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

If you got all YES - congratulations! You can go to the next step.

# 5. Start the web server

Application can be started with next command:

    # For test purposes
    sudo -u gitlab bundle exec rails s -e production

    # As daemon
    sudo -u gitlab bundle exec rails s -e production -d

You can login via web using admin generated with setup:

    admin@local.host
    5iveL!fe

#  6. Run Resque process (for processing job queue).

    # Manually
    sudo -u gitlab bundle exec rake environment resque:work QUEUE=* RAILS_ENV=production BACKGROUND=yes

    # GitLab start script
    sudo -u gitlab ./resque.sh
    # if you run this as root /home/gitlab/gitlab/tmp/pids/resque_worker.pid will be owned by root
    # causing the resque worker not to start via init script on next boot/service restart

## Customizing Resque's Redis connection

If you'd like Resque to connect to a Redis server on a non-standard port or on
a different host, you can configure its connection string in the
**config/resque.yml** file:

    production: redis.example.com:6379

**Ok - we have a working application now. **
**But keep going - there are some things that should be done **

# Nginx && Unicorn

## 1. Unicorn

    cd /home/gitlab/gitlab
    sudo -u gitlab cp config/unicorn.rb.example config/unicorn.rb
    sudo -u gitlab bundle exec unicorn_rails -c config/unicorn.rb -E production -D

## 2. Nginx

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
    /etc/init.d/nginx restart

## 3. Init script

Create init script in /etc/init.d/gitlab:

    sudo wget https://raw.github.com/gitlabhq/gitlab-recipes/master/init.d/gitlab -P /etc/init.d/
    sudo chmod +x /etc/init.d/gitlab

GitLab autostart:

    sudo update-rc.d gitlab defaults

Now you can start/restart/stop GitLab like:

    sudo /etc/init.d/gitlab restart
