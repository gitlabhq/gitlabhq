require 'active_record/fixtures'

namespace :gitlab do
  namespace :backup do
    # Create backup of GitLab system
    desc "GITLAB | Create a backup of the GitLab system"
    task create: :environment do
      warn_user_is_not_gitlab

      Rake::Task["gitlab:backup:db:create"].invoke
      Rake::Task["gitlab:backup:repo:create"].invoke
      Rake::Task["gitlab:backup:uploads:create"].invoke

      backup = Backup::Manager.new
      backup.pack
      backup.cleanup
      backup.remove_old
    end

    # Restore backup of GitLab system
    desc "GITLAB | Restore a previously created backup"
    task restore: :environment do
      warn_user_is_not_gitlab

      backup = Backup::Manager.new
      backup.unpack

      Rake::Task["gitlab:backup:db:restore"].invoke
      Rake::Task["gitlab:backup:repo:restore"].invoke
      Rake::Task["gitlab:backup:uploads:restore"].invoke
      Rake::Task["gitlab:shell:setup"].invoke

      backup.cleanup
    end

    namespace :repo do
      task create: :environment do
        puts "Dumping repositories ...".blue
        Backup::Repository.new.dump
        puts "done".green
      end

      task restore: :environment do
        puts "Restoring repositories ...".blue
        Backup::Repository.new.restore
        puts "done".green
      end
    end

    namespace :db do
      task create: :environment do
        puts "Dumping database ... ".blue
        Backup::Database.new.dump
        puts "done".green
      end

      task restore: :environment do
        puts "Restoring database ... ".blue
        Backup::Database.new.restore
        puts "done".green
      end
    end

    namespace :uploads do
      task create: :environment do
        puts "Dumping uploads ... ".blue
        Backup::Uploads.new.dump
        puts "done".green
      end

      task restore: :environment do
        puts "Restoring uploads ... ".blue
        Backup::Uploads.new.restore
        puts "done".green
      end
    end
  end # namespace end: backup
end # namespace end: gitlab
