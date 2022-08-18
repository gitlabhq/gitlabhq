# frozen_string_literal: true

require 'active_record/fixtures'

namespace :gitlab do
  namespace :backup do
    # Create backup of GitLab system
    desc 'GitLab | Backup | Create a backup of the GitLab system'
    task create: :gitlab_environment do
      warn_user_is_not_gitlab

      Backup::Manager.new(progress).create
    end

    # Restore backup of GitLab system
    desc 'GitLab | Backup | Restore a previously created backup'
    task restore: :gitlab_environment do
      warn_user_is_not_gitlab

      Backup::Manager.new(progress).restore
    end

    namespace :repo do
      task create: :gitlab_environment do
        Backup::Manager.new(progress).run_create_task('repositories')
      end

      task restore: :gitlab_environment do
        Backup::Manager.new(progress).run_restore_task('repositories')
      end
    end

    namespace :db do
      task create: :gitlab_environment do
        Backup::Manager.new(progress).run_create_task('main_db')
        Backup::Manager.new(progress).run_create_task('ci_db')
      end

      task restore: :gitlab_environment do
        Backup::Manager.new(progress).run_restore_task('main_db')
        Backup::Manager.new(progress).run_restore_task('ci_db')
      end
    end

    namespace :builds do
      task create: :gitlab_environment do
        Backup::Manager.new(progress).run_create_task('builds')
      end

      task restore: :gitlab_environment do
        Backup::Manager.new(progress).run_restore_task('builds')
      end
    end

    namespace :uploads do
      task create: :gitlab_environment do
        Backup::Manager.new(progress).run_create_task('uploads')
      end

      task restore: :gitlab_environment do
        Backup::Manager.new(progress).run_restore_task('uploads')
      end
    end

    namespace :artifacts do
      task create: :gitlab_environment do
        Backup::Manager.new(progress).run_create_task('artifacts')
      end

      task restore: :gitlab_environment do
        Backup::Manager.new(progress).run_restore_task('artifacts')
      end
    end

    namespace :pages do
      task create: :gitlab_environment do
        Backup::Manager.new(progress).run_create_task('pages')
      end

      task restore: :gitlab_environment do
        Backup::Manager.new(progress).run_restore_task('pages')
      end
    end

    namespace :lfs do
      task create: :gitlab_environment do
        Backup::Manager.new(progress).run_create_task('lfs')
      end

      task restore: :gitlab_environment do
        Backup::Manager.new(progress).run_restore_task('lfs')
      end
    end

    namespace :terraform_state do
      task create: :gitlab_environment do
        Backup::Manager.new(progress).run_create_task('terraform_state')
      end

      task restore: :gitlab_environment do
        Backup::Manager.new(progress).run_restore_task('terraform_state')
      end
    end

    namespace :registry do
      task create: :gitlab_environment do
        Backup::Manager.new(progress).run_create_task('registry')
      end

      task restore: :gitlab_environment do
        Backup::Manager.new(progress).run_restore_task('registry')
      end
    end

    namespace :packages do
      task create: :gitlab_environment do
        Backup::Manager.new(progress).run_create_task('packages')
      end

      task restore: :gitlab_environment do
        Backup::Manager.new(progress).run_restore_task('packages')
      end
    end

    def progress
      if ENV['CRON']
        # We need an object we can say 'puts' and 'print' to; let's use a
        # StringIO.
        require 'stringio'
        StringIO.new
      else
        $stdout
      end
    end
  end
  # namespace end: backup
end
# namespace end: gitlab
