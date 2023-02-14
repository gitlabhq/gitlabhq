# frozen_string_literal: true

namespace :gitlab do
  require 'active_record/fixtures'

  namespace :backup do
    PID = Process.pid.freeze
    PID_FILE = "#{Rails.application.root}/tmp/backup_restore.pid"

    # Create backup of GitLab system
    desc 'GitLab | Backup | Create a backup of the GitLab system'
    task create: :gitlab_environment do
      lock do
        warn_user_is_not_gitlab

        Backup::Manager.new(progress).create
      end
    end

    # Restore backup of GitLab system
    desc 'GitLab | Backup | Restore a previously created backup'
    task restore: :gitlab_environment do
      lock do
        warn_user_is_not_gitlab

        Backup::Manager.new(progress).restore
      end
    end

    namespace :repo do
      task create: :gitlab_environment do
        lock do
          Backup::Manager.new(progress).run_create_task('repositories')
        end
      end

      task restore: :gitlab_environment do
        lock do
          Backup::Manager.new(progress).run_restore_task('repositories')
        end
      end
    end

    namespace :db do
      task create: :gitlab_environment do
        lock do
          Backup::Manager.new(progress).run_create_task('db')
        end
      end

      task restore: :gitlab_environment do
        lock do
          Backup::Manager.new(progress).run_restore_task('db')
        end
      end
    end

    namespace :builds do
      task create: :gitlab_environment do
        lock do
          Backup::Manager.new(progress).run_create_task('builds')
        end
      end

      task restore: :gitlab_environment do
        lock do
          Backup::Manager.new(progress).run_restore_task('builds')
        end
      end
    end

    namespace :uploads do
      task create: :gitlab_environment do
        lock do
          Backup::Manager.new(progress).run_create_task('uploads')
        end
      end

      task restore: :gitlab_environment do
        lock do
          Backup::Manager.new(progress).run_restore_task('uploads')
        end
      end
    end

    namespace :artifacts do
      task create: :gitlab_environment do
        lock do
          Backup::Manager.new(progress).run_create_task('artifacts')
        end
      end

      task restore: :gitlab_environment do
        lock do
          Backup::Manager.new(progress).run_restore_task('artifacts')
        end
      end
    end

    namespace :pages do
      task create: :gitlab_environment do
        lock do
          Backup::Manager.new(progress).run_create_task('pages')
        end
      end

      task restore: :gitlab_environment do
        lock do
          Backup::Manager.new(progress).run_restore_task('pages')
        end
      end
    end

    namespace :lfs do
      task create: :gitlab_environment do
        lock do
          Backup::Manager.new(progress).run_create_task('lfs')
        end
      end

      task restore: :gitlab_environment do
        lock do
          Backup::Manager.new(progress).run_restore_task('lfs')
        end
      end
    end

    namespace :terraform_state do
      task create: :gitlab_environment do
        lock do
          Backup::Manager.new(progress).run_create_task('terraform_state')
        end
      end

      task restore: :gitlab_environment do
        lock do
          Backup::Manager.new(progress).run_restore_task('terraform_state')
        end
      end
    end

    namespace :registry do
      task create: :gitlab_environment do
        lock do
          Backup::Manager.new(progress).run_create_task('registry')
        end
      end

      task restore: :gitlab_environment do
        lock do
          Backup::Manager.new(progress).run_restore_task('registry')
        end
      end
    end

    namespace :packages do
      task create: :gitlab_environment do
        lock do
          Backup::Manager.new(progress).run_create_task('packages')
        end
      end

      task restore: :gitlab_environment do
        lock do
          Backup::Manager.new(progress).run_restore_task('packages')
        end
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

    def lock
      File.open(PID_FILE, File::RDWR | File::CREAT, 0644) do |f|
        f.flock(File::LOCK_EX)

        unless f.read.empty?
          # There is a PID inside so the process fails
          progress.puts(<<~HEREDOC.color(:red))
            Backup and restore in progress:
              There is a backup and restore task in progress. Please, try to run the current task once the previous one ends.
              If there is no other process running, please remove the PID file manually: rm #{PID_FILE}
          HEREDOC

          exit 1
        end

        f.write(PID)
        f.flush
      ensure
        f.flock(File::LOCK_UN)
      end

      begin
        yield
      ensure
        progress.puts "#{Time.now} " + "-- Deleting backup and restore lock file".color(:blue)
        File.delete(PID_FILE)
      end
    end
  end
  # namespace end: backup
end
# namespace end: gitlab
