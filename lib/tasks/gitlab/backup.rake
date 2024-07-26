# frozen_string_literal: true

module Tasks
  module Gitlab
    module Backup
      PID = Process.pid.freeze
      PID_FILE = "#{Rails.application.root}/tmp/backup_restore.pid"

      def self.create_backup
        lock_backup do
          ::Gitlab::TaskHelpers.warn_user_is_not_gitlab
          success = ::Backup::Manager.new(backup_progress).create
          exit 1 unless success
        end
      end

      def self.restore_backup
        lock_backup do
          ::Gitlab::TaskHelpers.warn_user_is_not_gitlab

          ::Backup::Manager.new(backup_progress).restore
        end
      end

      # Verify backup file to ensure it is compatible with current GitLab's version
      def self.verify_backup
        lock_backup do
          ::Backup::Manager.new(backup_progress).verify!
        end
      end

      def self.create_task(task_id)
        lock_backup do
          backup_manager = ::Backup::Manager.new(backup_progress)
          task = backup_manager.find_task(task_id)
          success = backup_manager.run_create_task(task)
          exit 1 unless success
        end
      end

      def self.restore_task(task_id)
        lock_backup do
          backup_manager = ::Backup::Manager.new(backup_progress)
          task = backup_manager.find_task(task_id)

          backup_manager.run_restore_task(task)
        end
      end

      def self.backup_progress
        if ENV['CRON']
          # We need an object we can say 'puts' and 'print' to; let's use a StringIO.
          StringIO.new
        else
          $stdout
        end
      end

      def self.lock_backup
        File.open(PID_FILE, File::RDWR | File::CREAT) do |f|
          f.flock(File::LOCK_EX)

          file_content = f.read

          read_pid(file_content) unless file_content.blank?

          f.rewind
          f.write(PID)
          f.flush
        ensure
          f.flock(File::LOCK_UN)
        end

        begin
          yield
        ensure
          backup_progress.puts(
            "#{Time.current} " +
              Rainbow('-- Deleting backup and restore PID file at [').blue +
              PID_FILE.to_s + Rainbow('] ... ').blue +
              Rainbow('done').green
          )
          File.delete(PID_FILE)
        end
      end

      def self.read_pid(file_content)
        Process.getpgid(file_content.to_i)

        backup_progress.puts(Rainbow(<<~MESSAGE).red)
          Backup and restore in progress:
            There is a backup and restore task in progress (PID #{file_content}).
            Try to run the current task once the previous one ends.
        MESSAGE

        exit 1
      rescue Errno::ESRCH
        backup_progress.puts(Rainbow(<<~MESSAGE).blue)
          The PID file #{PID_FILE} exists and contains #{file_content}, but the process is not running.
          The PID file will be rewritten with the current process ID #{PID}.
        MESSAGE
      end

      private_class_method :backup_progress, :lock_backup, :read_pid
    end
  end
end

namespace :gitlab do
  require 'active_record/fixtures'
  require 'stringio'

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
