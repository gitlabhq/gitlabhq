namespace :sidekiq do
  desc "GITLAB | Stop sidekiq"
  task :stop do
    run "bundle exec sidekiqctl stop #{pidfile}"
  end

  desc "GITLAB | Start sidekiq"
  task :start do
    run "nohup bundle exec sidekiq -q post_receive,mailer,system_hook,project_web_hook,gitolite,common,default -e #{Rails.env} -P #{pidfile} >> #{Rails.root.join("log", "sidekiq.log")} 2>&1 &"
  end

  def pidfile
    Rails.root.join("tmp", "pids", "sidekiq.pid")
  end
end
