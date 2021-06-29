# frozen_string_literal: true

require 'active_record/fixtures'

namespace :gitlab do
  namespace :backup do
    # Create backup of GitLab system
    desc 'GitLab | Backup | Create a backup of the GitLab system'
    task create: :gitlab_environment do
      warn_user_is_not_gitlab

      Rake::Task['gitlab:backup:db:create'].invoke
      Rake::Task['gitlab:backup:repo:create'].invoke
      Rake::Task['gitlab:backup:uploads:create'].invoke
      Rake::Task['gitlab:backup:builds:create'].invoke
      Rake::Task['gitlab:backup:artifacts:create'].invoke
      Rake::Task['gitlab:backup:pages:create'].invoke
      Rake::Task['gitlab:backup:lfs:create'].invoke
      Rake::Task['gitlab:backup:registry:create'].invoke

      backup = Backup::Manager.new(progress)
      backup.write_info

      if ENV['SKIP'] && ENV['SKIP'].include?('tar')
        backup.upload
      else
        backup.pack
        backup.upload
        backup.cleanup
        backup.remove_old
      end

      progress.puts "Warning: Your gitlab.rb and gitlab-secrets.json files contain sensitive data \n" \
           "and are not included in this backup. You will need these files to restore a backup.\n" \
           "Please back them up manually.".color(:red)
      progress.puts "Backup task is done."
    end

    # Restore backup of GitLab system
    desc 'GitLab | Backup | Restore a previously created backup'
    task restore: :gitlab_environment do
      warn_user_is_not_gitlab

      backup = Backup::Manager.new(progress)
      cleanup_required = backup.unpack
      backup.verify_backup_version

      unless backup.skipped?('db')
        begin
          unless ENV['force'] == 'yes'
            warning = <<-MSG.strip_heredoc
              Be sure to stop Puma, Sidekiq, and any other process that
              connects to the database before proceeding. For Omnibus
              installs, see the following link for more information:
              https://docs.gitlab.com/ee/raketasks/backup_restore.html#restore-for-omnibus-gitlab-installations

              Before restoring the database, we will remove all existing
              tables to avoid future upgrade problems. Be aware that if you have
              custom tables in the GitLab database these tables and all data will be
              removed.
            MSG
            puts warning.color(:red)
            ask_to_continue
            puts 'Removing all tables. Press `Ctrl-C` within 5 seconds to abort'.color(:yellow)
            sleep(5)
          end

          # Drop all tables Load the schema to ensure we don't have any newer tables
          # hanging out from a failed upgrade
          puts_time 'Cleaning the database ... '.color(:blue)
          Rake::Task['gitlab:db:drop_tables'].invoke
          puts_time 'done'.color(:green)
          Rake::Task['gitlab:backup:db:restore'].invoke
        rescue Gitlab::TaskAbortedByUserError
          puts "Quitting...".color(:red)
          exit 1
        end
      end

      Rake::Task['gitlab:backup:repo:restore'].invoke unless backup.skipped?('repositories')
      Rake::Task['gitlab:backup:uploads:restore'].invoke unless backup.skipped?('uploads')
      Rake::Task['gitlab:backup:builds:restore'].invoke unless backup.skipped?('builds')
      Rake::Task['gitlab:backup:artifacts:restore'].invoke unless backup.skipped?('artifacts')
      Rake::Task['gitlab:backup:pages:restore'].invoke unless backup.skipped?('pages')
      Rake::Task['gitlab:backup:lfs:restore'].invoke unless backup.skipped?('lfs')
      Rake::Task['gitlab:backup:registry:restore'].invoke unless backup.skipped?('registry')
      Rake::Task['gitlab:shell:setup'].invoke
      Rake::Task['cache:clear'].invoke

      if cleanup_required
        backup.cleanup
      end

      puts "Warning: Your gitlab.rb and gitlab-secrets.json files contain sensitive data \n" \
           "and are not included in this backup. You will need to restore these files manually.".color(:red)
      puts "Restore task is done."
    end

    namespace :repo do
      task create: :gitlab_environment do
        puts_time "Dumping repositories ...".color(:blue)

        max_concurrency = ENV.fetch('GITLAB_BACKUP_MAX_CONCURRENCY', 1).to_i
        max_storage_concurrency = ENV.fetch('GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY', 1).to_i

        if ENV["SKIP"] && ENV["SKIP"].include?("repositories")
          puts_time "[SKIPPED]".color(:cyan)
        elsif max_concurrency < 1 || max_storage_concurrency < 1
          puts "GITLAB_BACKUP_MAX_CONCURRENCY and GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY must have a value of at least 1".color(:red)
          exit 1
        else
          Backup::Repositories.new(progress, strategy: repository_backup_strategy).dump(
            max_concurrency: max_concurrency,
            max_storage_concurrency: max_storage_concurrency
          )
          puts_time "done".color(:green)
        end
      end

      task restore: :gitlab_environment do
        puts_time "Restoring repositories ...".color(:blue)
        Backup::Repositories.new(progress, strategy: repository_backup_strategy).restore
        puts_time "done".color(:green)
      end
    end

    namespace :db do
      task create: :gitlab_environment do
        puts_time "Dumping database ... ".color(:blue)

        if ENV["SKIP"] && ENV["SKIP"].include?("db")
          puts_time "[SKIPPED]".color(:cyan)
        else
          Backup::Database.new(progress).dump
          puts_time "done".color(:green)
        end
      end

      task restore: :gitlab_environment do
        puts_time "Restoring database ... ".color(:blue)
        errors = Backup::Database.new(progress).restore

        if errors.present?
          warning = <<~MSG
            There were errors in restoring the schema. This may cause
            issues if this results in missing indexes, constraints, or
            columns. Please record the errors above and contact GitLab
            Support if you have questions:
            https://about.gitlab.com/support/
          MSG

          warn warning.color(:red)
          ask_to_continue
        end

        puts_time "done".color(:green)
      end
    end

    namespace :builds do
      task create: :gitlab_environment do
        puts_time "Dumping builds ... ".color(:blue)

        if ENV["SKIP"] && ENV["SKIP"].include?("builds")
          puts_time "[SKIPPED]".color(:cyan)
        else
          Backup::Builds.new(progress).dump
          puts_time "done".color(:green)
        end
      end

      task restore: :gitlab_environment do
        puts_time "Restoring builds ... ".color(:blue)
        Backup::Builds.new(progress).restore
        puts_time "done".color(:green)
      end
    end

    namespace :uploads do
      task create: :gitlab_environment do
        puts_time "Dumping uploads ... ".color(:blue)

        if ENV["SKIP"] && ENV["SKIP"].include?("uploads")
          puts_time "[SKIPPED]".color(:cyan)
        else
          Backup::Uploads.new(progress).dump
          puts_time "done".color(:green)
        end
      end

      task restore: :gitlab_environment do
        puts_time "Restoring uploads ... ".color(:blue)
        Backup::Uploads.new(progress).restore
        puts_time "done".color(:green)
      end
    end

    namespace :artifacts do
      task create: :gitlab_environment do
        puts_time "Dumping artifacts ... ".color(:blue)

        if ENV["SKIP"] && ENV["SKIP"].include?("artifacts")
          puts_time "[SKIPPED]".color(:cyan)
        else
          Backup::Artifacts.new(progress).dump
          puts_time "done".color(:green)
        end
      end

      task restore: :gitlab_environment do
        puts_time "Restoring artifacts ... ".color(:blue)
        Backup::Artifacts.new(progress).restore
        puts_time "done".color(:green)
      end
    end

    namespace :pages do
      task create: :gitlab_environment do
        puts_time "Dumping pages ... ".color(:blue)

        if ENV["SKIP"] && ENV["SKIP"].include?("pages")
          puts_time "[SKIPPED]".color(:cyan)
        else
          Backup::Pages.new(progress).dump
          puts_time "done".color(:green)
        end
      end

      task restore: :gitlab_environment do
        puts_time "Restoring pages ... ".color(:blue)
        Backup::Pages.new(progress).restore
        puts_time "done".color(:green)
      end
    end

    namespace :lfs do
      task create: :gitlab_environment do
        puts_time "Dumping lfs objects ... ".color(:blue)

        if ENV["SKIP"] && ENV["SKIP"].include?("lfs")
          puts_time "[SKIPPED]".color(:cyan)
        else
          Backup::Lfs.new(progress).dump
          puts_time "done".color(:green)
        end
      end

      task restore: :gitlab_environment do
        puts_time "Restoring lfs objects ... ".color(:blue)
        Backup::Lfs.new(progress).restore
        puts_time "done".color(:green)
      end
    end

    namespace :registry do
      task create: :gitlab_environment do
        puts_time "Dumping container registry images ... ".color(:blue)

        if Gitlab.config.registry.enabled
          if ENV["SKIP"] && ENV["SKIP"].include?("registry")
            puts_time "[SKIPPED]".color(:cyan)
          else
            Backup::Registry.new(progress).dump
            puts_time "done".color(:green)
          end
        else
          puts_time "[DISABLED]".color(:cyan)
        end
      end

      task restore: :gitlab_environment do
        puts_time "Restoring container registry images ... ".color(:blue)

        if Gitlab.config.registry.enabled
          Backup::Registry.new(progress).restore
          puts_time "done".color(:green)
        else
          puts_time "[DISABLED]".color(:cyan)
        end
      end
    end

    def puts_time(msg)
      progress.puts "#{Time.now} -- #{msg}"
      Gitlab::BackupLogger.info(message: "#{Rainbow.uncolor(msg)}")
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

    def repository_backup_strategy
      if Feature.enabled?(:gitaly_backup)
        max_concurrency = ENV['GITLAB_BACKUP_MAX_CONCURRENCY'].presence
        Backup::GitalyBackup.new(progress, parallel: max_concurrency)
      else
        Backup::GitalyRpcBackup.new(progress)
      end
    end
  end
  # namespace end: backup
end
# namespace end: gitlab
