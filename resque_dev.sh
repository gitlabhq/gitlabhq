mkdir -p tmp/pids
nohup bundle exec rake environment resque:work QUEUE=post_receive,mailer,system_hook VVERBOSE=1 RAILS_ENV=development PIDFILE=tmp/pids/resque_worker.pid > ./log/resque.log  &
