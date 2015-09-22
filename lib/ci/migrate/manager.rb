module Ci
  module Migrate
    class Manager
      CI_IMPORT_PREFIX = '8.0' # Only allow imports from CI 8.0.x

      def cleanup
        $progress.print "Deleting tmp directories ... "

        backup_contents.each do |dir|
          next unless File.exist?(File.join(Gitlab.config.backup.path, dir))

          if FileUtils.rm_rf(File.join(Gitlab.config.backup.path, dir))
            $progress.puts "done".green
          else
            puts "deleting tmp directory '#{dir}' failed".red
            abort 'Backup failed'
          end
        end
      end

      def unpack
        Dir.chdir(Gitlab.config.backup.path)

        # check for existing backups in the backup dir
        file_list = Dir.glob("*_gitlab_ci_backup.tar").each.map { |f| f.split(/_/).first.to_i }
        puts "no backups found" if file_list.count == 0

        if file_list.count > 1 && ENV["BACKUP"].nil?
          puts "Found more than one backup, please specify which one you want to restore:"
          puts "rake gitlab:backup:restore BACKUP=timestamp_of_backup"
          exit 1
        end

        tar_file = ENV["BACKUP"].nil? ? File.join("#{file_list.first}_gitlab_ci_backup.tar") : File.join(ENV["BACKUP"] + "_gitlab_ci_backup.tar")

        unless File.exists?(tar_file)
          puts "The specified CI backup doesn't exist!"
          exit 1
        end

        $progress.print "Unpacking backup ... "

        unless Kernel.system(*%W(tar -xf #{tar_file}))
          puts "unpacking backup failed".red
          exit 1
        else
          $progress.puts "done".green
        end

        ENV["VERSION"] = "#{settings[:db_version]}" if settings[:db_version].to_i > 0

        # restoring mismatching backups can lead to unexpected problems
        if !settings[:gitlab_version].start_with?(CI_IMPORT_PREFIX)
          puts "GitLab CI version mismatch:".red
          puts "  Your current GitLab CI version (#{GitlabCi::VERSION}) differs from the GitLab CI (#{settings[:gitlab_version]}) version in the backup!".red
          exit 1
        end
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

