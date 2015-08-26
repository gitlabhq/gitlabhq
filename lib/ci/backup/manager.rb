module Ci
  module Backup
    class Manager
      def pack
        # saving additional informations
        s = {}
        s[:db_version]         = "#{ActiveRecord::Migrator.current_version}"
        s[:backup_created_at]  = Time.now
        s[:gitlab_version]     = GitlabCi::VERSION
        s[:tar_version]        = tar_version
        tar_file = "#{s[:backup_created_at].to_i}_gitlab_ci_backup.tar.gz"

        Dir.chdir(GitlabCi.config.backup.path) do
          File.open("#{GitlabCi.config.backup.path}/backup_information.yml",
                    "w+") do |file|
            file << s.to_yaml.gsub(/^---\n/,'')
          end

          FileUtils.chmod(0700, ["db", "builds"])

          # create archive
          $progress.print "Creating backup archive: #{tar_file} ... "
          orig_umask = File.umask(0077)
          if Kernel.system('tar', '-czf', tar_file, *backup_contents)
            $progress.puts "done".green
          else
            puts "creating archive #{tar_file} failed".red
            abort 'Backup failed'
          end
          File.umask(orig_umask)

          upload(tar_file)
        end
      end

      def upload(tar_file)
        remote_directory = GitlabCi.config.backup.upload.remote_directory
        $progress.print "Uploading backup archive to remote storage #{remote_directory} ... "

        connection_settings = GitlabCi.config.backup.upload.connection
        if connection_settings.blank?
          $progress.puts "skipped".yellow
          return
        end

        connection = ::Fog::Storage.new(connection_settings)
        directory = connection.directories.get(remote_directory)

        if directory.files.create(key: tar_file, body: File.open(tar_file), public: false,
            multipart_chunk_size: GitlabCi.config.backup.upload.multipart_chunk_size)
          $progress.puts "done".green
        else
          puts "uploading backup to #{remote_directory} failed".red
          abort 'Backup failed'
        end
      end

      def cleanup
        $progress.print "Deleting tmp directories ... "
        
        backup_contents.each do |dir|
          next unless File.exist?(File.join(GitlabCi.config.backup.path, dir))

          if FileUtils.rm_rf(File.join(GitlabCi.config.backup.path, dir))
            $progress.puts "done".green
          else
            puts "deleting tmp directory '#{dir}' failed".red
            abort 'Backup failed'
          end
        end
      end

      def remove_old
        # delete backups
        $progress.print "Deleting old backups ... "
        keep_time = GitlabCi.config.backup.keep_time.to_i

        if keep_time > 0
          removed = 0
          
          Dir.chdir(GitlabCi.config.backup.path) do
            file_list = Dir.glob('*_gitlab_ci_backup.tar.gz')
            file_list.map! { |f| $1.to_i if f =~ /(\d+)_gitlab_ci_backup.tar.gz/ }
            file_list.sort.each do |timestamp|
              if Time.at(timestamp) < (Time.now - keep_time)
                if Kernel.system(*%W(rm #{timestamp}_gitlab_ci_backup.tar.gz))
                  removed += 1
                end
              end
            end
          end

          $progress.puts "done. (#{removed} removed)".green
        else
          $progress.puts "skipping".yellow
        end
      end

      def unpack
        Dir.chdir(GitlabCi.config.backup.path)

        # check for existing backups in the backup dir
        file_list = Dir.glob("*_gitlab_ci_backup.tar.gz").each.map { |f| f.split(/_/).first.to_i }
        puts "no backups found" if file_list.count == 0

        if file_list.count > 1 && ENV["BACKUP"].nil?
          puts "Found more than one backup, please specify which one you want to restore:"
          puts "rake gitlab:backup:restore BACKUP=timestamp_of_backup"
          exit 1
        end

        tar_file = ENV["BACKUP"].nil? ? File.join("#{file_list.first}_gitlab_ci_backup.tar.gz") : File.join(ENV["BACKUP"] + "_gitlab_ci_backup.tar.gz")

        unless File.exists?(tar_file)
          puts "The specified backup doesn't exist!"
          exit 1
        end

        $progress.print "Unpacking backup ... "

        unless Kernel.system(*%W(tar -xzf #{tar_file}))
          puts "unpacking backup failed".red
          exit 1
        else
          $progress.puts "done".green
        end

        ENV["VERSION"] = "#{settings[:db_version]}" if settings[:db_version].to_i > 0

        # restoring mismatching backups can lead to unexpected problems
        if settings[:gitlab_version] != GitlabCi::VERSION
          puts "GitLab CI version mismatch:".red
          puts "  Your current GitLab CI version (#{GitlabCi::VERSION}) differs from the GitLab CI version in the backup!".red
          puts "  Please switch to the following version and try again:".red
          puts "  version: #{settings[:gitlab_version]}".red
          puts
          puts "Hint: git checkout v#{settings[:gitlab_version]}"
          exit 1
        end
      end

      def tar_version
        tar_version = `tar --version`
        tar_version.force_encoding('locale').split("\n").first
      end

      private

      def backup_contents
        ["db", "builds", "backup_information.yml"]
      end

      def settings
        @settings ||= YAML.load_file("backup_information.yml")
      end
    end
  end
end
