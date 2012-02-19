mkdir tmp/pids
nohup bundle exec rake environment resque:work QUEUE=* RAILS_ENV=production PIDFILE=tmp/pids/resque_worker_QUEUE.pid & >> log/resque_worker_QUEUE.log 2>&1
