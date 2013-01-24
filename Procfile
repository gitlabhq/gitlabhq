web: bundle exec unicorn_rails -p $PORT -c ./config/unicorn.rb -E $RAILS_ENV
worker: bundle exec sidekiq -q post_receive,mailer,system_hook,project_web_hook,common,default -e $RAILS_ENV