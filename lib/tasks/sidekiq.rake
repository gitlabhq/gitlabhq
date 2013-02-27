namespace :sidekiq do
  desc "GITLAB | Stop sidekiq"
  task :stop do
    system "bundle exec sidekiqctl stop #{pidfile}"
  end

  desc "GITLAB | Start sidekiq"
  task :start do
    system "nohup bundle exec sidekiq -q post_receive,mailer,system_hook,project_web_hook,gitlab_shell,common,default -e #{Rails.env} -P #{pidfile} >> #{Rails.root.join("log", "sidekiq.log")} 2>&1 &"
  end

  desc "GITLAB | Start sidekiq with launchd on Mac OS X"
  task :launchd do
    system "bundle exec sidekiq -q post_receive,mailer,system_hook,project_web_hook,gitlab_shell,common,default -e #{Rails.env} -P #{pidfile} >> #{Rails.root.join("log", "sidekiq.log")} 2>&1"
  end

  def pidfile
    Rails.root.join("tmp", "pids", "sidekiq.pid")
  end
end
