web: bundle exec unicorn_rails -p $PORT
worker: bundle exec sidekiq -q post_receive,mailer,system_hook,project_web_hook,common,default,gitolite
