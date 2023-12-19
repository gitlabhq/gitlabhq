# frozen_string_literal: true

namespace :gitlab do
  desc 'GitLab | Check the configuration of GitLab and its environment'
  task check: :gitlab_environment do
    SystemCheck::RakeTask::GitlabTask.run!
  end

  namespace :app do
    desc 'GitLab | App | Check the configuration of the GitLab Rails app'
    task check: :gitlab_environment do
      SystemCheck::RakeTask::AppTask.run!
    end
  end

  namespace :gitlab_shell do
    desc 'GitLab | GitLab Shell | Check the configuration of GitLab Shell'
    task check: :gitlab_environment do
      SystemCheck::RakeTask::GitlabShellTask.run!
    end
  end

  namespace :gitaly do
    desc 'GitLab | Gitaly | Check the health of Gitaly'
    task check: :gitlab_environment do
      SystemCheck::RakeTask::GitalyTask.run!
    end
  end

  namespace :sidekiq do
    desc 'GitLab | Sidekiq | Check the configuration of Sidekiq'
    task check: :gitlab_environment do
      SystemCheck::RakeTask::SidekiqTask.run!
    end
  end

  namespace :incoming_email do
    desc 'GitLab | Incoming Email | Check the configuration of Reply by email'
    task check: :gitlab_environment do
      SystemCheck::RakeTask::IncomingEmailTask.run!
    end
  end

  namespace :ldap do
    task :check, [:limit] => :gitlab_environment do |_, args|
      ENV['LDAP_CHECK_LIMIT'] = args.limit if args.limit.present?

      SystemCheck::RakeTask::LdapTask.run!
    end
  end
end
