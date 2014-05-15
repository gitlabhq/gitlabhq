module Backup
  class Manager
    BACKUP_CONTENTS = %w{repositories/ db/ uploads/ backup_information.yml}

    def pack
      # saving additional informations
      s = {}
      s[:db_version]         = "#{ActiveRecord::Migrator.current_version}"
      s[:backup_created_at]  = Time.now
      s[:gitlab_version]     = Gitlab::VERSION
      s[:tar_version]        = tar_version

      Dir.chdir(Gitlab.config.backup.path)

      File.open("#{Gitlab.config.backup.path}/backup_information.yml", "w+") do |file|
        file << s.to_yaml.gsub(/^---\n/,'')
      end

      # create archive
      print "Creating backup archive: #{s[:backup_created_at].to_i}_gitlab_backup.tar ... "
      if Kernel.system('tar', '-cf', "#{s[:backup_created_at].to_i}_gitlab_backup.tar", *BACKUP_CONTENTS)
        puts "done".green
      else
        puts "failed".red
      end
    end

    def cleanup
      print "Deleting tmp directories ... "
      if Kernel.system('rm', '-rf', *BACKUP_CONTENTS)
        puts "done".green
      else
        puts "failed".red
      end
    end

    def remove_old
      # delete backups
      print "Deleting old backups ... "
      keep_time = Gitlab.config.backup.keep_time.to_i
      path = Gitlab.config.backup.path

      if keep_time > 0
        removed = 0
        file_list = Dir.glob(Rails.root.join(path, "*_gitlab_backup.tar"))
        file_list.map! { |f| $1.to_i if f =~ /(\d+)_gitlab_backup.tar/ }
        file_list.sort.each do |timestamp|
          if Time.at(timestamp) < (Time.now - keep_time)
            if Kernel.system(*%W(rm #{timestamp}_gitlab_backup.tar))
              removed += 1
            end
          end
        end
        puts "done. (#{removed} removed)".green
      else
        puts "skipping".yellow
      end
    end

    def unpack
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
      unless Kernel.system(*%W(tar -xf #{tar_file}))
        puts "failed".red
        exit 1
      else
        puts "done".green
      end

      settings = YAML.load_file("backup_information.yml")
      ENV["VERSION"] = "#{settings[:db_version]}" if settings[:db_version].to_i > 0

      # restoring mismatching backups can lead to unexpected problems
      if settings[:gitlab_version] != Gitlab::VERSION
        puts "GitLab version mismatch:".red
        puts "  Your current GitLab version (#{Gitlab::VERSION}) differs from the GitLab version in the backup!".red
        puts "  Please switch to the following version and try again:".red
        puts "  version: #{settings[:gitlab_version]}".red
        puts
        puts "Hint: git checkout v#{settings[:gitlab_version]}"
        exit 1
      end
    end

    def tar_version
      tar_version, _ = Gitlab::Popen.popen(%W(tar --version))
      tar_version.force_encoding('locale').split("\n").first
    end
  end
end
