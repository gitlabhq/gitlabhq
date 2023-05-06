# frozen_string_literal: true

module Tasks
  module Gitlab
    module Backup
      PID = Process.pid.freeze
      PID_FILE = "#{Rails.application.root}/tmp/backup_restore.pid"
    end
  end
end

namespace :gitlab do
  require 'active_record/fixtures'

  namespace :backup do
    # Create backup of GitLab system
    desc 'GitLab | Backup | Create a backup of the GitLab system'
    task create: :gitlab_environment do
      lock_backup do
        warn_user_is_not_gitlab

        Backup::Manager.new(backup_progress).create
      end
    end

    # Restore backup of GitLab system
    desc 'GitLab | Backup | Restore a previously created backup'
    task restore: :gitlab_environment do
      lock_backup do
        warn_user_is_not_gitlab

        Backup::Manager.new(backup_progress).restore
      end
    end

    namespace :repo do
      task create: :gitlab_environment do
        lock_backup do
          Backup::Manager.new(backup_progress).run_create_task('repositories')
        end
      end

      task restore: :gitlab_environment do
        lock_backup do
          Backup::Manager.new(backup_progress).run_restore_task('repositories')
        end
      end
    end

    namespace :db do
      task create: :gitlab_environment do
        lock_backup do
          Backup::Manager.new(backup_progress).run_create_task('db')
        end
      end

      task restore: :gitlab_environment do
        lock_backup do
          Backup::Manager.new(backup_progress).run_restore_task('db')
        end
      end
    end

    namespace :builds do
      task create: :gitlab_environment do
        lock_backup do
          Backup::Manager.new(backup_progress).run_create_task('builds')
        end
      end

      task restore: :gitlab_environment do
        lock_backup do
          Backup::Manager.new(backup_progress).run_restore_task('builds')
        end
      end
    end

    namespace :uploads do
      task create: :gitlab_environment do
        lock_backup do
          Backup::Manager.new(backup_progress).run_create_task('uploads')
        end
      end

      task restore: :gitlab_environment do
        lock_backup do
          Backup::Manager.new(backup_progress).run_restore_task('uploads')
        end
      end
    end

    namespace :artifacts do
      task create: :gitlab_environment do
        lock_backup do
          Backup::Manager.new(backup_progress).run_create_task('artifacts')
        end
      end

      task restore: :gitlab_environment do
        lock_backup do
          Backup::Manager.new(backup_progress).run_restore_task('artifacts')
        end
      end
    end

    namespace :pages do
      task create: :gitlab_environment do
        lock_backup do
          Backup::Manager.new(backup_progress).run_create_task('pages')
        end
      end

      task restore: :gitlab_environment do
        lock_backup do
          Backup::Manager.new(backup_progress).run_restore_task('pages')
        end
      end
    end

    namespace :lfs do
      task create: :gitlab_environment do
        lock_backup do
          Backup::Manager.new(backup_progress).run_create_task('lfs')
        end
      end

      task restore: :gitlab_environment do
        lock_backup do
          Backup::Manager.new(backup_progress).run_restore_task('lfs')
        end
      end
    end

    namespace :terraform_state do
      task create: :gitlab_environment do
        lock_backup do
          Backup::Manager.new(backup_progress).run_create_task('terraform_state')
        end
      end

      task restore: :gitlab_environment do
        lock_backup do
          Backup::Manager.new(backup_progress).run_restore_task('terraform_state')
        end
      end
    end

    namespace :registry do
      task create: :gitlab_environment do
        lock_backup do
          Backup::Manager.new(backup_progress).run_create_task('registry')
        end
      end

      task restore: :gitlab_environment do
        lock_backup do
          Backup::Manager.new(backup_progress).run_restore_task('registry')
        end
      end
    end

    namespace :packages do
      task create: :gitlab_environment do
        lock_backup do
          Backup::Manager.new(backup_progress).run_create_task('packages')
        end
      end

      task restore: :gitlab_environment do
        lock_backup do
          Backup::Manager.new(backup_progress).run_restore_task('packages')
        end
      end
    end

    private

    def backup_progress
      if ENV['CRON']
        # We need an object we can say 'puts' and 'print' to; let's use a
        # StringIO.
        require 'stringio'
        StringIO.new
      else
        $stdout
      end
    end

    def lock_backup
      File.open(Tasks::Gitlab::Backup::PID_FILE, File::RDWR | File::CREAT) do |f|
        f.flock(File::LOCK_EX)

        file_content = f.read

        read_pid(file_content) unless file_content.blank?

        f.rewind
        f.write(Tasks::Gitlab::Backup::PID)
        f.flush
      ensure
        f.flock(File::LOCK_UN)
      end

      begin
        yield
      ensure
        backup_progress.puts(
          "#{Time.current} " + '-- Deleting backup and restore PID file ... '.color(:blue) + 'done'.color(:green)
        )
        File.delete(Tasks::Gitlab::Backup::PID_FILE)
      end
    end

    def read_pid(file_content)
      Process.getpgid(file_content.to_i)

      backup_progress.puts(<<~MESSAGE.color(:red))
        Backup and restore in progress:
          There is a backup and restore task in progress (PID #{file_content}). Try to run the current task once the previous one ends.
      MESSAGE

      exit 1
    rescue Errno::ESRCH
      backup_progress.puts(<<~MESSAGE.color(:blue))
        The PID file #{Tasks::Gitlab::Backup::PID_FILE} exists and contains #{file_content}, but the process is not running.
        The PID file will be rewritten with the current process ID #{Tasks::Gitlab::Backup::PID}.
      MESSAGE
    end
  end
  # namespace end: backup
end
# namespace end: gitlab
