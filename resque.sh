mkdir tmp/pids
nohup bundle exec rake environment resque:work QUEUE=* RAILS_ENV=production PIDFILE=tmp/pids/resque_worker.pid & >> log/resque_worker.log 2>&1
