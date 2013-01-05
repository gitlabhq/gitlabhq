require 'active_record/fixtures'

namespace :gitlab do
  namespace :backup do
    # Create backup of GitLab system
    desc "GITLAB | Create a backup of the GitLab system"
    task :create => :environment do
      warn_user_is_not_gitlab

      Rake::Task["gitlab:backup:db:create"].invoke
      Rake::Task["gitlab:backup:repo:create"].invoke

      Dir.chdir(Gitlab.config.backup.path)

      # saving additional informations
      s = {}
      s[:db_version]         = "#{ActiveRecord::Migrator.current_version}"
      s[:backup_created_at]  = "#{Time.now}"
      s[:gitlab_version]     = %x{git rev-parse HEAD}.gsub(/\n/,"")
      s[:tar_version]        = %x{tar --version | head -1}.gsub(/\n/,"")

      File.open("#{Gitlab.config.backup.path}/backup_information.yml", "w+") do |file|
        file << s.to_yaml.gsub(/^---\n/,'')
      end

      # create archive
      print "Creating backup archive: #{Time.now.to_i}_gitlab_backup.tar ... "
      if Kernel.system("tar -cf #{Time.now.to_i}_gitlab_backup.tar repositories/ db/ backup_information.yml")
        puts "done".green
      else
        puts "failed".red
      end

      # cleanup: remove tmp files
      print "Deleting tmp directories ... "
      if Kernel.system("rm -rf repositories/ db/ backup_information.yml")
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
    task :restore => :environment do
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

      # restoring mismatching backups can lead to unexpected problems
      if settings[:gitlab_version] != %x{git rev-parse HEAD}.gsub(/\n/,"")
        puts "GitLab version mismatch:".red
        puts "  Your current HEAD differs from the HEAD in the backup!".red
        puts "  Please switch to the following revision and try again:".red
        puts "  revision: #{settings[:gitlab_version]}".red
        exit 1
      end

      Rake::Task["gitlab:backup:db:restore"].invoke
      Rake::Task["gitlab:backup:repo:restore"].invoke

      # cleanup: remove tmp files
      print "Deleting tmp directories ... "
      if Kernel.system("rm -rf repositories/ db/ backup_information.yml")
        puts "done".green
      else
        puts "failed".red
      end
    end

    ################################################################################
    ################################# invoked tasks ################################

    ################################# REPOSITORIES #################################

    namespace :repo do
      task :create => :environment do
        backup_path_repo = File.join(Gitlab.config.backup.path, "repositories")
        FileUtils.mkdir_p(backup_path_repo) until Dir.exists?(backup_path_repo)
        puts "Dumping repositories ...".blue

        Project.find_each(:batch_size => 1000) do |project|
          print " * #{project.path_with_namespace} ... "

          if project.empty_repo?
            puts "[SKIPPED]".cyan
            next
          end

          # Create namespace dir if missing
          FileUtils.mkdir_p(File.join(backup_path_repo, project.namespace.path)) if project.namespace

          # Build a destination path for backup
          path_to_bundle  = File.join(backup_path_repo, project.path_with_namespace + ".bundle")

          if Kernel.system("cd #{project.repository.path_to_repo} > /dev/null 2>&1 && git bundle create #{path_to_bundle} --all > /dev/null 2>&1")
            puts "[DONE]".green
          else
            puts "[FAILED]".red
          end
        end
      end

      task :restore => :environment do
        backup_path_repo = File.join(Gitlab.config.backup.path, "repositories")
        repos_path = Gitlab.config.gitolite.repos_path

        puts "Restoring repositories ... "

        Project.find_each(:batch_size => 1000) do |project|
          print "#{project.path_with_namespace} ... "

          if project.namespace
            project.namespace.ensure_dir_exist
          end

          # Build a backup path
          path_to_bundle  = File.join(backup_path_repo, project.path_with_namespace + ".bundle")

          if Kernel.system("git clone --bare #{path_to_bundle} #{project.repository.path_to_repo} > /dev/null 2>&1")
            puts "[DONE]".green
          else
            puts "[FAILED]".red
          end
        end
      end
    end

    ###################################### DB ######################################

    namespace :db do
      task :create => :environment do
        backup_path_db = File.join(Gitlab.config.backup.path, "db")
        FileUtils.mkdir_p(backup_path_db) unless Dir.exists?(backup_path_db)

        puts "Dumping database tables ... ".blue
        ActiveRecord::Base.connection.tables.each do |tbl|
          print " * #{tbl.yellow} ... "
          count = 1
          File.open(File.join(backup_path_db, tbl + ".yml"), "w+") do |file|
            ActiveRecord::Base.connection.select_all("SELECT * FROM `#{tbl}`").each do |line|
              line.delete_if{|k,v| v.blank?}
              output = {tbl + '_' + count.to_s => line}
              file << output.to_yaml.gsub(/^---\n/,'') + "\n"
              count += 1
            end
            puts "done".green
          end
        end
      end

      task :restore => :environment do
        backup_path_db = File.join(Gitlab.config.backup.path, "db")

        puts "Restoring database tables (loading fixtures) ... "
        Rake::Task["db:reset"].invoke

        Dir.glob(File.join(backup_path_db, "*.yml") ).each do |dir|
          fixture_file = File.basename(dir, ".*" )
          print "#{fixture_file.yellow} ... "
          if File.size(dir) > 0
            ActiveRecord::Fixtures.create_fixtures(backup_path_db, fixture_file)
            puts "done".green
          else
            puts "skipping".yellow
          end
        end
      end
    end

  end # namespace end: backup
end # namespace end: gitlab
