namespace :sidekiq do
  desc "GITLAB | Stop sidekiq"
  task :stop do
    system *%W(script/background_jobs stop)
  end

  desc "GITLAB | Start sidekiq"
  task :start do
    system *%W(script/background_jobs start)
  end

  desc 'GitLab | Restart sidekiq'
  task :restart do
    system *%W(script/background_jobs restart)
  end

  desc "GITLAB | Start sidekiq with launchd on Mac OS X"
  task :launchd do
    system *%W(script/background_jobs start_no_deamonize)
  end
end
