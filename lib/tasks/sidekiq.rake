namespace :sidekiq do
  def deprecation_warning!
    warn <<~WARNING
      This task is deprecated and will be removed in 13.0 as it is thought to be unused.

      If you are using this task, please comment on the below issue:
        https://gitlab.com/gitlab-org/gitlab/issues/196731
    WARNING
  end

  desc "[DEPRECATED] GitLab | Stop sidekiq"
  task :stop do
    deprecation_warning!

    system(*%w(bin/background_jobs stop))
  end

  desc "[DEPRECATED] GitLab | Start sidekiq"
  task :start do
    deprecation_warning!

    system(*%w(bin/background_jobs start))
  end

  desc '[DEPRECATED] GitLab | Restart sidekiq'
  task :restart do
    deprecation_warning!

    system(*%w(bin/background_jobs restart))
  end

  desc "[DEPRECATED] GitLab | Start sidekiq with launchd on Mac OS X"
  task :launchd do
    deprecation_warning!

    system(*%w(bin/background_jobs start_no_deamonize))
  end
end
