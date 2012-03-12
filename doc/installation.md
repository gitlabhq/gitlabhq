Проект gitlab рассчитан на операционную систему Linux. Имеются сведения о успешной установке ее на FreeBSD и Mac OS, однако мы официально не тестируем на этих системах данный проект и не гарантируем его корректной работы.
Данная интсрукция написана для систем Debian/Ubuntu.

Установка проекта gitlab состоит из 6 частей:

1. install packeges.
2. install ruby
3. install gitolite
4. install gitlab and configuration. Check status configuration.
5. server up.
6. run resque process (for processing queue).

Большая просьба - прежде чем составлять отчет об ошибке убедитесь что все шаги вы проделали верно.

Первые 3 шага возможно проделать автоматически, для этого установите curl:
    #для Debian может понадобиться установить утилиту sudo 
    apt-get install curl sudo
    
    # 3 step in 1 command
    curl http://dl.dropbox.com/u/936096/debian_ubuntu.sh | sh

Затем можно приступать к установке:


# 1. Install packages

*Имейте ввиду что в debian по умолчанию не установлена утилита sudo. Установите ее от юзера root:*     **apt-get update && apt-get upgrade && apt-get install sudo**

    sudo apt-get update
    sudo apt-get upgrade

    sudo apt-get install -y git-core wget curl gcc checkinstall libxml2-dev libxslt-dev sqlite3 libsqlite3-dev libcurl4-openssl-dev libreadline-dev libc6-dev libssl-dev libmysql++-dev make build-essential zlib1g-dev libicu-dev redis-server openssh-server git-core python-dev python-pip sendmail

# 2. Install ruby

    wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p290.tar.gz
    tar xfvz ruby-1.9.2-p290.tar.gz
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

получение исходников gitolite:
    cd /home/git
    sudo -H -u git git clone git://github.com/gitlabhq/gitolite /home/git/gitolite    

Setup:
    sudo -u git -H /home/git/gitolite/src/gl-system-install
    sudo cp /home/gitlab/.ssh/id_rsa.pub /home/git/gitlab.pub
    sudo chmod 777 /home/git/gitlab.pub

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

Если вам не удалось успешно склонировать репозиторий - вы что-то сделали не так. Перепроверьте предидущие шаги. ДАЛЬНЕЙШАЯ УСТАНОВКА БУДЕТ БЕЗУСПЕШНА.

# 4. Install gitlab and configuration. Check status configuration.

    sudo gem install charlock_holmes
    sudo pip install pygments
    sudo gem install bundler
    cd /home/gitlab
    sudo -H -u gitlab git clone git://github.com/gitlabhq/gitlabhq.git gitlab
    cd gitlab

    # Rename config files
    sudo -u gitlab cp config/gitlab.yml.example config/gitlab.yml

#### Select db you want to use
    # SQLite
    sudo -u gitlab cp config/database.yml.sqlite config/database.yml

    # Or 
    # Mysql
    sudo -u gitlab cp config/database.yml.example config/database.yml

#### Install gems
    sudo -u gitlab -H bundle install --without development test --deployment

#### Setup DB
    sudo -u gitlab bundle exec rake db:setup RAILS_ENV=production
    sudo -u gitlab bundle exec rake db:seed_fu RAILS_ENV=production
    
Checking status:
    sudo -u gitlab bundle exec rake gitlab_status


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

If you have all YES then go next.
Поздравляем!!! установка завершена. Теперь необходимо запустить сервисы.

# 5. Server up

Сервер можно запустить простой командой:
    sudo -u gitlab bundle exec rails s -e production
Однако этот способ даст вам только возможность проверить работоспособность сервиса, не более. Чтобы запустить сервис в виде демона, сделайте так
    sudo -u gitlab bundle exec rails s -e production -d


#  6. Run resque process (for processing queue).

    # Manually
    sudo -u gitlab bundle exec rake environment resque:work QUEUE=* RAILS_ENV=production BACKGROUND=yes

    # Gitlab start script
    ./resque.sh

# Nginx && Unicorn

### Install Nginx

    sudo apt-get install nginx

## Unicorn
    cd /home/gitlab/gitlab
    sudo -u gitlab cp config/unicorn.rb.orig config/unicorn.rb
    sudo -u gitlab unicorn_rails -c config/unicorn.rb -E production -D

В nginx.conf добавим блок upstream в секцию http:
    upstream gitlab {
        server unix:/tmp/gitlab.socket;
    }
И добавим virtual host:

    server {
        listen 80;
        server_name mygitlab.com;

        location / {

            root /home/gitlab/gitlab/public;

            if (!-f $request_filename) {
                proxy_pass http://gitlab; 
                break;
            }
        }

    }

mygitlab.com - change to your domain.
Restart nginx:
    /etc/init.d/nginx restart
Create init script in /etc/init.d/gitlab:
    #! /bin/bash
    ### BEGIN INIT INFO
    # Provides:          unicorn
    # Required-Start:    $local_fs $remote_fs $network $syslog
    # Required-Stop:     $local_fs $remote_fs $network $syslog
    # Default-Start:     2 3 4 5
    # Default-Stop:      0 1 6
    # Short-Description: starts the unicorn web server
    # Description:       starts unicorn
    ### END INIT INFO
    
    DAEMON_OPTS="-c /home/gitlab/gitlab/config/unicorn.rb -E production -D"
    NAME=unicorn
    DESC="Gitlab service"
    PID=/home/gitlab/gitlab/tmp/pids/unicorn.pid

    case "$1" in
      start)
            CD_TO_APP_DIR="cd /home/gitlab/gitlab"
            START_DAEMON_PROCESS="bundle exec unicorn_rails $DAEMON_OPTS"

            echo -n "Starting $DESC: "
            if [ `whoami` = root ]; then
              sudo -u gitlab sh -c "$CD_TO_APP_DIR > /dev/null 2>&1 && $START_DAEMON_PROCESS"
            else
              $CD_TO_APP_DIR > /dev/null 2>&1 && $START_DAEMON_PROCESS
            fi
            echo "$NAME."
            ;;
      stop)
            echo -n "Stopping $DESC: "
            kill -QUIT `cat $PID`
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

When server is rebooted then gitlab must starting:
    sudo update-rc.d gitlab defaults

