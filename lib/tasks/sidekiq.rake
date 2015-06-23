namespace :sidekiq do
  desc "GitLab | Stop sidekiq"
  task :stop do
    system *%W(bin/background_jobs stop)
  end

  desc "GitLab | Start sidekiq"
  task :start do
    system *%W(bin/background_jobs start)
  end

  desc 'GitLab | Restart sidekiq'
  task :restart do
    system *%W(bin/background_jobs restart)
  end

  desc "GitLab | Start sidekiq with launchd on Mac OS X"
  task :launchd do
    system *%W(bin/background_jobs start_no_deamonize)
  end
end
