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

DAEMON_OPTS="-c /var/www/gitlabhq/config/unicorn.rb -E production -D"
NAME=unicorn
DESC="Gitlab service"
PID=/var/www/gitlabhq/tmp/pids/unicorn.pid
RESQUE_PID=/var/www/gitlabhq/tmp/pids/resque_worker.pid

case "$1" in
  start)
        CD_TO_APP_DIR="cd /var/www/gitlabhq"
        START_DAEMON_PROCESS="bundle exec unicorn_rails $DAEMON_OPTS"
        START_RESQUE_PROCESS="./resque.sh"

        echo -n "Starting $DESC: "
        if [ `whoami` = root ]; then
          su - gitlab -c "sh -l -c \"$CD_TO_APP_DIR > /dev/null 2>&1 && $START_DAEMON_PROCESS && $START_RESQUE_PROCESS\"" 
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
        kill -USR2 `cat $RESQUE_PID`
        echo "$NAME."
        ;;
  reload)
        echo -n "Reloading $DESC configuration: "
        kill -HUP `cat $PID`
        kill -HUP `cat $RESQUE_PID`
        echo "$NAME."
        ;;
  *)
        echo "Usage: $NAME {start|stop|restart|reload}" >&2
        exit 1
        ;;
esac

exit 0

