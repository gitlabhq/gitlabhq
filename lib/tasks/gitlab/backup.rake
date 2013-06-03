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


      # saving additional informations
      s = {}
      s[:db_version]         = "#{ActiveRecord::Migrator.current_version}"
      s[:backup_created_at]  = Time.now
      s[:gitlab_version]     = %x{git rev-parse HEAD}.gsub(/\n/,"")
      s[:tar_version]        = %x{tar --version | head -1}.gsub(/\n/,"")

      Dir.chdir(Gitlab.config.backup.path)

      File.open("#{Gitlab.config.backup.path}/backup_information.yml", "w+") do |file|
        file << s.to_yaml.gsub(/^---\n/,'')
      end

      # create archive
      print "Creating backup archive: #{s[:backup_created_at].to_i}_gitlab_backup.tar ... "
      if Kernel.system("tar -cf #{s[:backup_created_at].to_i}_gitlab_backup.tar repositories/ db/ uploads/ backup_information.yml")
        puts "done".green
      else
        puts "failed".red
      end

      # cleanup: remove tmp files
      print "Deleting tmp directories ... "
      if Kernel.system("rm -rf repositories/ db/ uploads/ backup_information.yml")
        puts "done".green
      else
        puts "failed".red
      end

      # delete backups
      print "Deleting old backups ... "
      if Gitlab.config.backup.keep_time > 0
        file_list = Dir.glob("*_gitlab_backup.tar").map { |f| f.split(/_/).first.to_i }
        file_list.sort.each do |timestamp|
          if Time.at(timestamp) < (Time.now - Gitlab.config.backup.keep_time)
            %x{rm #{timestamp}_gitlab_backup.tar}
          end
        end
        puts "done".green
      else
        puts "skipping".yellow
      end
    end

    # Restore backup of GitLab system
    desc "GITLAB | Restore a previously created backup"
    task restore: :environment do
      warn_user_is_not_gitlab

      Dir.chdir(Gitlab.config.backup.path)

      # check for existing backups in the backup dir
      file_list = Dir.glob("*_gitlab_backup.tar").each.map { |f| f.split(/_/).first.to_i }
      puts "no backups found" if file_list.count == 0
      if file_list.count > 1 && ENV["BACKUP"].nil?
        puts "Found more than one backup, please specify which one you want to restore:"
        puts "rake gitlab:backup:restore BACKUP=timestamp_of_backup"
        exit 1
      end

      tar_file = ENV["BACKUP"].nil? ? File.join("#{file_list.first}_gitlab_backup.tar") : File.join(ENV["BACKUP"] + "_gitlab_backup.tar")

      unless File.exists?(tar_file)
        puts "The specified backup doesn't exist!"
        exit 1
      end

      print "Unpacking backup ... "
      unless Kernel.system("tar -xf #{tar_file}")
        puts "failed".red
        exit 1
      else
        puts "done".green
      end

      settings = YAML.load_file("backup_information.yml")
      ENV["VERSION"] = "#{settings[:db_version]}" if settings[:db_version].to_i > 0

      # backups directory is not always sub of Rails root and able to execute the git rev-parse below
      begin
        Dir.chdir(Rails.root)

        # restoring mismatching backups can lead to unexpected problems
        if settings[:gitlab_version] != %x{git rev-parse HEAD}.gsub(/\n/, "")
          puts "GitLab version mismatch:".red
          puts "  Your current HEAD differs from the HEAD in the backup!".red
          puts "  Please switch to the following revision and try again:".red
          puts "  revision: #{settings[:gitlab_version]}".red
          exit 1
        end
      ensure
        # chdir back to original intended dir
        Dir.chdir(Gitlab.config.backup.path)
      end

      Rake::Task["gitlab:backup:db:restore"].invoke
      Rake::Task["gitlab:backup:repo:restore"].invoke
      Rake::Task["gitlab:backup:uploads:restore"].invoke
      Rake::Task["gitlab:shell:setup"].invoke

      # cleanup: remove tmp files
      print "Deleting tmp directories ... "
      if Kernel.system("rm -rf repositories/ db/ uploads/ backup_information.yml")
        puts "done".green
      else
        puts "failed".red
      end
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
