# frozen_string_literal: true

namespace :gitlab do
  namespace :backup do
    # Create backup of GitLab system
    desc 'GitLab | Backup | Create a backup of the GitLab system'
    task create: :gitlab_environment do
      Tasks::Gitlab::Backup.create_backup
    end

    # Restore backup of GitLab system
    desc 'GitLab | Backup | Restore a previously created backup'
    task restore: :gitlab_environment do
      Tasks::Gitlab::Backup.restore_backup
    end

    desc 'GitLab | Backup | Verify a previously created backup'
    task verify: :gitlab_environment do
      Tasks::Gitlab::Backup.verify_backup
    end

    namespace :repo do
      task create: :gitlab_environment do
        Tasks::Gitlab::Backup.create_task('repositories')
      end

      task restore: :gitlab_environment do
        Tasks::Gitlab::Backup.restore_task('repositories')
      end

      task reset_pool_repositories: :gitlab_environment do
        Tasks::Gitlab::Backup.reset_pool_repositories!
      end
    end

    namespace :db do
      task create: :gitlab_environment do
        Tasks::Gitlab::Backup.create_task('db')
      end

      task restore: :gitlab_environment do
        Tasks::Gitlab::Backup.restore_task('db')
      end
    end

    namespace :builds do
      task create: :gitlab_environment do
        Tasks::Gitlab::Backup.create_task('builds')
      end

      task restore: :gitlab_environment do
        Tasks::Gitlab::Backup.restore_task('builds')
      end
    end

    namespace :uploads do
      task create: :gitlab_environment do
        Tasks::Gitlab::Backup.create_task('uploads')
      end

      task restore: :gitlab_environment do
        Tasks::Gitlab::Backup.restore_task('uploads')
      end
    end

    namespace :artifacts do
      task create: :gitlab_environment do
        Tasks::Gitlab::Backup.create_task('artifacts')
      end

      task restore: :gitlab_environment do
        Tasks::Gitlab::Backup.restore_task('artifacts')
      end
    end

    namespace :pages do
      task create: :gitlab_environment do
        Tasks::Gitlab::Backup.create_task('pages')
      end

      task restore: :gitlab_environment do
        Tasks::Gitlab::Backup.restore_task('pages')
      end
    end

    namespace :lfs do
      task create: :gitlab_environment do
        Tasks::Gitlab::Backup.create_task('lfs')
      end

      task restore: :gitlab_environment do
        Tasks::Gitlab::Backup.restore_task('lfs')
      end
    end

    namespace :terraform_state do
      task create: :gitlab_environment do
        Tasks::Gitlab::Backup.create_task('terraform_state')
      end

      task restore: :gitlab_environment do
        Tasks::Gitlab::Backup.restore_task('terraform_state')
      end
    end

    namespace :registry do
      task create: :gitlab_environment do
        Tasks::Gitlab::Backup.create_task('registry')
      end

      task restore: :gitlab_environment do
        Tasks::Gitlab::Backup.restore_task('registry')
      end
    end

    namespace :packages do
      task create: :gitlab_environment do
        Tasks::Gitlab::Backup.create_task('packages')
      end

      task restore: :gitlab_environment do
        Tasks::Gitlab::Backup.restore_task('packages')
      end
    end

    namespace :ci_secure_files do
      task create: :gitlab_environment do
        Tasks::Gitlab::Backup.create_task('ci_secure_files')
      end

      task restore: :gitlab_environment do
        Tasks::Gitlab::Backup.restore_task('ci_secure_files')
      end
    end

    namespace :external_diffs do
      task create: :gitlab_environment do
        Tasks::Gitlab::Backup.create_task('external_diffs')
      end

      task restore: :gitlab_environment do
        Tasks::Gitlab::Backup.restore_task('external_diffs')
      end
    end
  end
  # namespace end: backup
end
# namespace end: gitlab
