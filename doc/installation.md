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

Gitlab does **not** run on Windows and we have no plans of making Gitlab compatible.

## This installation guide created for Debian/Ubuntu and properly tested. 

The installation consists of 6 steps:

1. Install packages / dependencies
2. Install ruby
3. Install gitolite
4. Install and configure Gitlab.
5. Start the web front-end
6. Start a Resque worker (for background processing)

### IMPORTANT

Please make sure you have followed all the steps below before posting to the mailinglist with installation and configuration questions.

Only create a Github Issue if you want a specific part of this installation guide updated.

Also read the [Read this before you submit an issue](https://github.com/gitlabhq/gitlabhq/wiki/Read-this-before-you-submit-an-issue) wiki page.

> - - -
> First 3 steps can be easily skipped with simply install script:
> 
>     # Install curl and sudo 
>     apt-get install curl sudo
>     
>     # 3 steps in 1 command :)
>     curl https://raw.github.com/gitlabhq/gitlabhq/master/doc/debian_ubuntu.sh | sh
> 
> Now you can go to step 4"
> - - -

# 1. Install packages

*Keep in mind that `sudo` is not installed for debian by default. You should install it with as root:*     **apt-get update && apt-get upgrade && apt-get install sudo**

    sudo apt-get update
    sudo apt-get upgrade

    sudo apt-get install -y wget curl gcc checkinstall libxml2-dev libxslt-dev sqlite3 libsqlite3-dev libcurl4-openssl-dev libreadline6-dev libc6-dev libssl-dev libmysql++-dev make build-essential zlib1g-dev libicu-dev redis-server openssh-server git-core python-dev python-pip libyaml-dev postfix
    
    # If you want to use MySQL:
    sudo apt-get install -y mysql-server mysql-client libmysqlclient-dev

# 2. Install ruby

    wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p290.tar.gz
    tar xzfv ruby-1.9.2-p290.tar.gz
    cd ruby-1.9.2-p290
    ./configure
    make
    sudo make install

# 3. Install gitolite

Create user for git:
    
    sudo adduser \
      --system \
      --shell /bin/sh \
      --gecos 'git version control' \
      --group \
      --disabled-password \
      --home /home/git \
      git

Create user for gitlab:

    # ubuntu/debian
    sudo adduser --disabled-login --gecos 'gitlab system' gitlab    

Add your user to git group:

    sudo usermod -a -G git gitlab

Generate key:

    sudo -H -u gitlab ssh-keygen -q -N '' -t rsa -f /home/gitlab/.ssh/id_rsa

Get gitolite source code:

    cd /home/git
    sudo -H -u git git clone git://github.com/gitlabhq/gitolite /home/git/gitolite    

Setup:

    sudo -u git sh -c 'echo -e "PATH=\$PATH:/home/git/bin\nexport PATH" >> /home/git/.profile'
    sudo -u git -H sh -c "PATH=/home/git/bin:$PATH; /home/git/gitolite/src/gl-system-install"
    sudo cp /home/gitlab/.ssh/id_rsa.pub /home/git/gitlab.pub
    sudo chmod 0444 /home/git/gitlab.pub

    sudo -u git -H sed -i 's/0077/0007/g' /home/git/share/gitolite/conf/example.gitolite.rc
    sudo -u git -H sh -c "PATH=/home/git/bin:$PATH; gl-setup -q /home/git/gitlab.pub"
    
Permissions:

    sudo chmod -R g+rwX /home/git/repositories/
    sudo chown -R git:git /home/git/repositories/

#### CHECK: Logout & login again to apply git group to your user
    
    # clone admin repo to add localhost to known_hosts
    # & be sure your user has access to gitolite
    sudo -u gitlab -H git clone git@localhost:gitolite-admin.git /tmp/gitolite-admin 

    # if succeed  you can remove it
    sudo rm -rf /tmp/gitolite-admin 

**IMPORTANT! If you cant clone `gitolite-admin` repository - DONT PROCEED INSTALLATION**

# 4. Install gitlab and configuration. Check status configuration.

    sudo gem install charlock_holmes --version '0.6.8'
    sudo pip install pygments
    sudo gem install bundler
    cd /home/gitlab
    sudo -H -u gitlab git clone -b stable git://github.com/gitlabhq/gitlabhq.git gitlab
    cd gitlab
    
    sudo -u gitlab mkdir tmp

    # Rename config files
    sudo -u gitlab cp config/gitlab.yml.example config/gitlab.yml

#### Select db you want to use

    # SQLite
    sudo -u gitlab cp config/database.yml.sqlite config/database.yml

    # Or 
    # Mysql
    # Install MySQL as directed in Step #1
    
    # Login to MySQL
    $ mysql -u root -p 
    
    # Create the gitlabhq production database
    mysql> CREATE DATABASE IF NOT EXISTS `gitlabhq_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;
    
    # Create the MySQL User change $password to a real password
    mysql> CREATE USER 'gitlab'@'localhost' IDENTIFIED BY '$password'; 
    
    # Grant proper permissions to the MySQL User
    mysql> GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON `gitlabhq_production`.* TO 'gitlab'@'localhost';
    
    # Exit MySQL Server and copy the example config, make sure to update username/password in config/database.yml
    sudo -u gitlab cp config/database.yml.example config/database.yml

#### Install gems

    sudo -u gitlab -H bundle install --without development test --deployment

#### Setup DB

    sudo -u gitlab bundle exec rake gitlab:app:setup RAILS_ENV=production

#### Setup gitlab hooks

    sudo cp ./lib/hooks/post-receive /home/git/share/gitolite/hooks/common/post-receive
    sudo chown git:git /home/git/share/gitolite/hooks/common/post-receive
    
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

If you got all YES - congrats! You can go to next step.  

# 5. Server up

Application can be started with next command:

    # For test purposes 
    sudo -u gitlab bundle exec rails s -e production

    # As daemon
    sudo -u gitlab bundle exec rails s -e production -d

You can login via web using admin generated with setup:

    admin@local.host
    5iveL!fe

#  6. Run resque process (for processing queue).

    # Manually
    sudo -u gitlab bundle exec rake environment resque:work QUEUE=* RAILS_ENV=production BACKGROUND=yes

    # Gitlab start script
    sudo -u gitlab ./resque.sh
    # if you run this as root /home/gitlab/gitlab/tmp/pids/resque_worker.pid will be owned by root
    # causing the resque worker not to start via init script on next boot/service restart

**Ok - we have a working application now. **
**But keep going - there are some thing that should be done **

# Nginx && Unicorn

### Install Nginx

    sudo apt-get install nginx

## Unicorn

    cd /home/gitlab/gitlab
    sudo -u gitlab cp config/unicorn.rb.orig config/unicorn.rb
    sudo -u gitlab bundle exec unicorn_rails -c config/unicorn.rb -E production -D

Edit /etc/nginx/nginx.conf. In the *http* section add:

    upstream gitlab {
        server unix:/home/gitlab/gitlab/tmp/sockets/gitlab.socket;
    }

    server {
        listen YOUR_SERVER_IP:80;         # e.g., listen 192.168.1.1:80;
        server_name YOUR_SERVER_FQDN;     # e.g., server_name source.example.com;
        root /home/gitlab/gitlab/public;
        
        # individual nginx logs for this gitlab vhost
        access_log  /var/log/nginx/gitlab_access.log;
        error_log   /var/log/nginx/gitlab_error.log;
        
        location / {
            # serve static files from defined root folder;.
            # @gitlab is a named location for the upstream fallback, see below
            try_files $uri $uri/index.html $uri.html @gitlab;
        }
        
        # if a file, which is not found in the root folder is requested, 
        # then the proxy pass the request to the upsteam (gitlab unicorn)
        location @gitlab {
          proxy_redirect     off;
          
          # you need to change this to "https", if you set "ssl" directive to "on"
          proxy_set_header   X-FORWARDED_PROTO http;
          proxy_set_header   Host              $http_host;
          proxy_set_header   X-Real-IP         $remote_addr;
        
          proxy_pass http://gitlab;
        }
    }

Change **YOUR_SERVER_IP** and **YOUR_SERVER_FQDN** to the IP address and fully-qualified domain name of the host serving GitLab.

Restart nginx:

    /etc/init.d/nginx restart

Create init script in /etc/init.d/gitlab:

    #! /bin/bash
    ### BEGIN INIT INFO
    # Provides:          gitlab
    # Required-Start:    $local_fs $remote_fs $network $syslog redis-server
    # Required-Stop:     $local_fs $remote_fs $network $syslog
    # Default-Start:     2 3 4 5
    # Default-Stop:      0 1 6
    # Short-Description: GitLab git repository management
    # Description:       GitLab git repository management
    ### END INIT INFO
    
    DAEMON_OPTS="-c /home/gitlab/gitlab/config/unicorn.rb -E production -D"
    NAME=unicorn
    DESC="Gitlab service"
    PID=/home/gitlab/gitlab/tmp/pids/unicorn.pid
    RESQUE_PID=/home/gitlab/gitlab/tmp/pids/resque_worker.pid

    case "$1" in
      start)
            CD_TO_APP_DIR="cd /home/gitlab/gitlab"
            START_DAEMON_PROCESS="bundle exec unicorn_rails $DAEMON_OPTS"
            START_RESQUE_PROCESS="./resque.sh"

            echo -n "Starting $DESC: "
            if [ `whoami` = root ]; then
              sudo -u gitlab sh -l -c "$CD_TO_APP_DIR > /dev/null 2>&1 && $START_DAEMON_PROCESS && $START_RESQUE_PROCESS"
            else
              $CD_TO_APP_DIR > /dev/null 2>&1 && $START_DAEMON_PROCESS && $START_RESQUE_PROCESS
            fi
            echo "$NAME."
            ;;
      stop)
            echo -n "Stopping $DESC: "
            kill -QUIT `cat $PID`
            kill -QUIT `cat $RESQUE_PID`
            echo "$NAME."
            ;;
      restart)
            echo -n "Restarting $DESC: "
            kill -USR2 `cat $PID`
            echo "$NAME."
            ;;
      reload)
            echo -n "Reloading $DESC configuration: "
            kill -HUP `cat $PID`
            echo "$NAME."
            ;;
      *)
            echo "Usage: $NAME {start|stop|restart|reload}" >&2
            exit 1
            ;;
    esac

    exit 0

Adding permission:

    sudo chmod +x /etc/init.d/gitlab

Gitlab autostart:

    sudo update-rc.d gitlab defaults

Now you can start/restart/stop gitlab like:

    sudo /etc/init.d/gitlab restart
