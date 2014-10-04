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
      tar_file = "#{s[:backup_created_at].to_i}_gitlab_backup.tar"

      Dir.chdir(Gitlab.config.backup.path)

      File.open("#{Gitlab.config.backup.path}/backup_information.yml", "w+") do |file|
        file << s.to_yaml.gsub(/^---\n/,'')
      end

      # create archive
      print "Creating backup archive: #{tar_file} ... "
      if Kernel.system('tar', '-cf', tar_file, *BACKUP_CONTENTS)
      else
        puts "failed".red
        abort 'Backup failed'
      end
      puts 'done'.green

      tar_file = compress(tar_file)
      upload(tar_file)
    end

    def compress(tar_file)
      print "Compressing backup archive: #{tar_file} ... "

      compression_extensions = {
        gzip:     '.gz',
        bzip2:    '.bz2',
        xz:       '.xz'
      }

      compression_cmd = Gitlab.config.backup.compression[:command]
      compression_lvl = Gitlab.config.backup.compression[:level]
      if compression_cmd.blank?
        puts 'skipped'.yellow
        return tar_file
      end

      if Kernel.system(compression_cmd, compression_lvl.blank? ? '--' : "-#{compression_lvl}", tar_file)
      else
        puts 'failed'.red
        abort 'Compression failed'
      end
      puts 'done'.green

      # Return the new tar file name
      compression_ext = compression_extensions[compression_cmd.to_sym]
      "#{tar_file}#{compression_ext}"
    end

    def upload(tar_file)
      remote_directory = Gitlab.config.backup.upload.remote_directory
      print "Uploading backup archive to remote storage #{remote_directory} ... "

      connection_settings = Gitlab.config.backup.upload.connection
      if connection_settings.blank?
        puts "skipped".yellow
        return
      end

      connection = ::Fog::Storage.new(connection_settings)
      directory = connection.directories.get(remote_directory)
      if directory.files.create(key: tar_file, body: File.open(tar_file), public: false)
        puts "done".green
      else
        puts "failed".red
        abort 'Backup failed'
      end
    end

    def cleanup
      print "Deleting tmp directories ... "
      if Kernel.system('rm', '-rf', *BACKUP_CONTENTS)
        puts "done".green
      else
        puts "failed".red
        abort 'Backup failed'
      end
    end

    def remove_old
      # delete backups
      print "Deleting old backups ... "
      keep_time = Gitlab.config.backup.keep_time.to_i
      path = Gitlab.config.backup.path

      if keep_time > 0
        removed = 0
        file_list = Dir.glob(Rails.root.join(path, '*_gitlab_backup.tar*'))
        file_list.sort.each do |tar_file|
          timestamp = $1.to_i if tar_file =~ /(\d+)_gitlab_backup.tar*/
          if Time.at(timestamp) < (Time.now - keep_time)
            if Kernel.system('rm', tar_file)
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
      file_list = Dir.glob('*_gitlab_backup.tar*').each.map { |f| f.split(/_/).first.to_i }
      puts "no backups found" if file_list.count == 0
      if file_list.count > 1 && ENV["BACKUP"].nil?
        puts "Found more than one backup, please specify which one you want to restore:"
        puts "rake gitlab:backup:restore BACKUP=timestamp_of_backup"
        exit 1
      end

      tar_file = ENV["BACKUP"].nil? ? File.join("#{file_list.first}_gitlab_backup.tar") : File.join(ENV["BACKUP"] + "_gitlab_backup.tar")

      was_compressed = false
      ['.gz', '.bz2', '.xz'].each do |compress_ext|
        compressed_file = "#{tar_file}#{compress_ext}"
        if File.exists?(compressed_file)
          uncompress compressed_file, compress_ext
          was_compressed = true
        end
      end

      puts tar_file
      unless File.exists?(tar_file)
        puts "The specified backup doesn't exist!"
        exit 1
      end

      print "Unpacking backup: #{tar_file} ... "
      unless Kernel.system(*%W(tar -xf #{tar_file}))
        puts "failed".red
        exit 1
      else
        puts "done".green
      end

      if was_compressed
        print "Deleting uncompressed backup: #{tar_file} ... "
        if Kernel.system('rm', '-f', tar_file)
          puts 'done'.green
        else
          puts 'failed'.red
          exit 1
        end
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

    def uncompress(tar_file, compress_ext)
      print "Uncompressing backup: #{tar_file} ... "

      uncompression_commands = {
        '.gz'     => 'gzip',
        '.bz2'    => 'bzip2',
        '.xz'     => 'xz'
      }
      uncompression_cmd = uncompression_commands[compress_ext]

      if Kernel.system(uncompression_cmd, '-kd', tar_file)
        puts 'done'.green
      else
        puts 'failed'.red
        exit 1
      end
    end

    def tar_version
      tar_version, _ = Gitlab::Popen.popen(%W(tar --version))
      tar_version.force_encoding('locale').split("\n").first
    end
  end
end
