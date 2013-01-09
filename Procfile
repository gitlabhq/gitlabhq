web: bundle exec rails s -p $PORT
worker: bundle exec sidekiq -q post_receive,mailer,system_hook,common,default
