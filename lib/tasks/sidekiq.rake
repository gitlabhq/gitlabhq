namespace :sidekiq do
  desc "GITLAB | Stop sidekiq"
  task :stop do
    run "bundle exec sidekiqctl stop #{pidfile}"
  end

  desc "GITLAB | Start sidekiq"
  task :start do
    run "nohup bundle exec sidekiq -q post_receive,mailer,system_hook,common,default -e #{rails_env} -P #{pidfile} >> #{root_path}/log/sidekiq.log 2>&1 &"
  end

  def root_path
    @root_path ||= File.join(File.expand_path(File.dirname(__FILE__)), "../..")
  end

  def pidfile
    "#{root_path}/tmp/pids/sidekiq.pid"
  end

  def rails_env
    ENV['RAILS_ENV'] || "production"
  end
end
