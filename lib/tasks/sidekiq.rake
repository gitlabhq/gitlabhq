namespace :sidekiq do
  desc "GITLAB | Stop sidekiq"
  task :stop do
    system "bundle exec sidekiqctl stop #{pidfile}"
  end

  desc "GITLAB | Start sidekiq"
  task :start => :restart

  desc 'GitLab | Restart sidekiq'
  task :restart do
    if File.exist?(pidfile)
      puts 'Shutting down existing sidekiq process.'
      Rake::Task['sidekiq:stop'].invoke
      puts 'Starting new sidekiq process.'
    end
    system "nohup bundle exec sidekiq -q post_receive,mailer,system_hook,project_web_hook,gitlab_shell,common,default -e #{Rails.env} -P #{pidfile} >> #{log_file} 2>&1 &"
  end

  desc "GITLAB | Start sidekiq with launchd on Mac OS X"
  task :launchd do
    system "bundle exec sidekiq -q post_receive,mailer,system_hook,project_web_hook,gitlab_shell,common,default -e #{Rails.env} -P #{pidfile} >> #{log_file} 2>&1"
  end

  def pidfile
    Rails.root.join("tmp", "pids", "sidekiq.pid")
  end

  def log_file
    Rails.root.join("log", "sidekiq.log")
  end
end
