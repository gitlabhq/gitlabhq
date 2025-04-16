# frozen_string_literal: true

module Tasks
  module Gitlab
    module Backup
      PID = Process.pid.freeze
      PID_FILE = "#{Rails.application.root}/tmp/backup_restore.pid".freeze

      def self.create_backup
        lock_backup do
          ::Gitlab::TaskHelpers.warn_user_is_not_gitlab
          success = ::Backup::Manager.new(backup_progress).create

          exit 1 unless success # rubocop:disable Rails/Exit -- Rake task helper
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

          exit 1 unless success # rubocop:disable Rails/Exit -- Rake task helper
        end
      end

      def self.restore_task(task_id)
        lock_backup do
          backup_manager = ::Backup::Manager.new(backup_progress)
          task = backup_manager.find_task(task_id)

          backup_manager.run_restore_task(task)
        end
      end

      # A Backup only includes regular repositories, after a restore we need to reinitialize their respective pools.
      # This process is done by changing its original state to 'none' and scheduling its creation process again
      def self.reset_pool_repositories!
        ::Backup::Restore::PoolRepositories.reinitialize_pools! do |pool_result|
          puts pool_result.to_h.to_json
        end
      end

      def self.backup_progress
        # We need an object we can say 'puts' and 'print' to; let's use a StringIO.
        return StringIO.new if ENV['CRON']

        $stdout
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

        exit 1 # rubocop:disable Rails/Exit -- Rake task helper
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
