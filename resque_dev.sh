mkdir -p tmp/pids
bundle exec rake environment resque:work QUEUE=post_receive,mailer,system_hook VVERBOSE=1 PIDFILE=tmp/pids/resque_worker.pid RAILS_ENV=development BACKGROUND=yes
