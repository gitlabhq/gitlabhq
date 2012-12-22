require 'active_record/fixtures'

namespace :gitlab do
  namespace :backup do
    # Create backup of GitLab system
    desc "GITLAB | Create a backup of the GitLab system"
    task :create => :environment do
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
      print "Creating backup archive: #{Time.now.to_i}_gitlab_backup.tar "
      if Kernel.system("tar -cf #{Time.now.to_i}_gitlab_backup.tar repositories/ db/ backup_information.yml")
        puts "[DONE]".green
      else
        puts "[FAILED]".red
      end

      # cleanup: remove tmp files
      print "Deleting tmp directories..."
      if Kernel.system("rm -rf repositories/ db/ backup_information.yml")
        puts "[DONE]".green
      else
        puts "[FAILED]".red
      end

      # delete backups
      print "Deleting old backups... "
      if Gitlab.config.backup.keep_time > 0
        file_list = Dir.glob("*_gitlab_backup.tar").map { |f| f.split(/_/).first.to_i }
        file_list.sort.each do |timestamp|
          if Time.at(timestamp) < (Time.now - Gitlab.config.backup.keep_time)
            %x{rm #{timestamp}_gitlab_backup.tar}
          end
        end
        puts "[DONE]".green
      else
        puts "[SKIPPING]".yellow
      end
    end

    # Restore backup of GitLab system
    desc "GITLAB | Restore a previously created backup"
    task :restore => :environment do

      if Process.uid != 0
        puts "Please run the restore as root user".red
        exit 1
      end

      Dir.chdir(Gitlab.config.backup.path)

      # check for existing backups in the backup dir
      file_list = Dir.glob("*_gitlab_backup.tar").each.map { |f| f.split(/_/).first.to_i }
      puts "no backups found" if file_list.count == 0
      if file_list.count > 1 && ENV["BACKUP"].nil?
        puts "Found more than one backup, please specify which one you want to restore:"
        puts "rake gitlab:backup:restore BACKUP=timestamp_of_backup"
        exit 1;
      end

      tar_file = ENV["BACKUP"].nil? ? File.join("#{file_list.first}_gitlab_backup.tar") : File.join(ENV["BACKUP"] + "_gitlab_backup.tar")

      unless File.exists?(tar_file)
        puts "The specified backup doesn't exist!"
        exit 1;
      end

      print "Unpacking backup... "
      unless Kernel.system("tar -xf #{tar_file}")
        puts "[FAILED]".red
        exit 1
      else
        puts "[DONE]".green
      end

      settings = YAML.load_file("backup_information.yml")
      ENV["VERSION"] = "#{settings[:db_version]}" if settings[:db_version].to_i > 0

      # restoring mismatching backups can lead to unexpected problems
      if settings[:gitlab_version] != %x{git rev-parse HEAD}.gsub(/\n/,"")
        puts "gitlab_version mismatch:".red
        puts "  Your current HEAD differs from the HEAD in the backup!".red
        puts "  Please switch to the following revision and try again:".red
        puts "  revision: #{settings[:gitlab_version]}".red
        exit 1
      end

      Rake::Task["gitlab:backup:db:restore"].invoke
      Rake::Task["gitlab:backup:repo:restore"].invoke

      # cleanup: remove tmp files
      print "Deleting tmp directories..."
      if Kernel.system("rm -rf repositories/ db/ backup_information.yml")
        puts "[DONE]".green
      else
        puts "[FAILED]".red
      end
    end

    ################################################################################
    ################################# invoked tasks ################################

    ################################# REPOSITORIES #################################

    namespace :repo do
      task :create => :environment do
        backup_path_repo = File.join(Gitlab.config.backup.path, "repositories")
        FileUtils.mkdir_p(backup_path_repo) until Dir.exists?(backup_path_repo)

        # Gitlab repositories 
        puts "Dumping repositories:"
        Project.all.each do |project|
          print "- Dumping repository '#{project.path_with_namespace}.git'... "
          unless project.empty_repo?

            namespace       = project.namespace? ? project.namespace.path : "/"
            path_to_bundle  = File.join(backup_path_repo, project.path_with_namespace + ".bundle")
            FileUtils.mkdir_p(File.join(backup_path_repo, namespace))

            if Kernel.system("cd #{project.path_to_repo} > /dev/null 2>&1 && git bundle create #{path_to_bundle} --all > /dev/null 2>&1")
              puts "[DONE]".green
            else
              puts "[FAILED]".red
            end

          else
            puts "[SKIPPING]".yellow
          end
        end

        # Non gitlab managed repositories
        [ "gitolite-admin.git", "testing.git" ].each do |repository|
          path_to_repo    = File.join(Gitlab.config.git_base_path, repository)
          path_to_bundle  = File.join(backup_path_repo, repository + ".bundle")

          print "- Dumping repository '#{repository}'... "
          if Grit::Repo.new(path_to_repo).head_count == 0
            puts "[SKIPPING]".yellow
          else
            if Kernel.system("cd #{path_to_repo} > /dev/null 2>&1 && git bundle create #{path_to_bundle} --all > /dev/null 2>&1")
              puts "[DONE]".green
            else
              puts "[FAILED]".red
            end
          end
        end
      end # create

      task :restore => :environment do
        backup_path_repo    = File.join(Gitlab.config.backup.path, "repositories")
        repos_in_backup     = Dir.chdir(backup_path_repo) && Dir.glob("{*.bundle,*/*.bundle}")
        permission_commands = [
          "sudo chmod -R g+rwX #{Gitlab.config.git_base_path}",
          "sudo chown -R #{Gitlab.config.ssh_user}:#{Gitlab.config.ssh_user} #{Gitlab.config.git_base_path}",
          "sudo -u git -Hi /home/git/bin/gitolite compile" # recreates gitolite access files in repositories
        ]

        # Gitlab repositories 
        puts "Restoring repositories:"
        Project.all.each do |project|

          print "- Restoring repository '#{project.path_with_namespace}.git'... "
          FileUtils.rm_rf(project.path_to_repo) if File.dirname(project.path_to_repo)

          if repos_in_backup.include?(project.path_with_namespace + ".bundle") # true: we can restore the repo from backup

            namespace         = project.namespace? ? project.namespace.path : "/"
            path_to_bundle    = File.join(backup_path_repo, project.path_with_namespace + ".bundle")
            path_to_repo_base = File.join(Gitlab.config.git_base_path, namespace)

            FileUtils.mkdir_p(project.path_to_repo) until Dir.exists?(path_to_repo_base)

            if Kernel.system("git clone --bare #{path_to_bundle} #{project.path_to_repo} > /dev/null 2>&1")
              puts "[DONE]".green
            else
              puts "[FAILED]".red
            end

          else # false: need to create a new empty repo
            if Grit::Repo.init_bare(project.path_to_repo)
              puts "[DONE]".green
            else
              puts "[FAILED]".red
            end
          end
        end # |project|

        # Non gitlab managed repositories
        [ "gitolite-admin.git", "testing.git" ].each do |repository|
          path_to_bundle        = File.join(backup_path_repo, repository + ".bundle")
          path_to_restore_point = File.join(Gitlab.config.git_base_path, repository)

          print "- Restoring repository '#{repository}'... "
          FileUtils.rm_rf(path_to_restore_point) if File.dirname(path_to_restore_point)

          if File.exists?(path_to_bundle)
            if Kernel.system("git clone --bare #{path_to_bundle} #{path_to_restore_point} > /dev/null 2>&1")
              puts "[DONE]".green
            else
              puts "[FAILED]".red
            end
          else
            if Grit::Repo.init_bare(path_to_restore_point)
              puts "[DONE]".green
            else
              puts "[FAILED]".red
            end
          end
        end

        # Fixing repository permissions
        permission_commands.each { |command| Kernel.system(command) }
      end # restore
    end # repo

    ###################################### DB ######################################

    namespace :db do
      task :create => :environment do
        backup_path_db = File.join(Gitlab.config.backup.path, "db")
        FileUtils.mkdir_p(backup_path_db) unless Dir.exists?(backup_path_db)

        puts "Dumping database tables:"
        ActiveRecord::Base.connection.tables.each do |tbl|
          print "- Dumping table #{tbl}... "
          count = 1
          File.open(File.join(backup_path_db, tbl + ".yml"), "w+") do |file|
            ActiveRecord::Base.connection.select_all("SELECT * FROM `#{tbl}`").each do |line|
              line.delete_if{|k,v| v.blank?}
              output = {tbl + '_' + count.to_s => line}
              file << output.to_yaml.gsub(/^---\n/,'') + "\n"
              count += 1
            end
            puts "[DONE]".green
          end
        end
      end

      task :restore=> :environment do
        backup_path_db = File.join(Gitlab.config.backup.path, "db")

        puts "Restoring database tables:"
        Rake::Task["db:reset"].invoke

        Dir.glob(File.join(backup_path_db, "*.yml") ).each do |dir|
          fixture_file = File.basename(dir, ".*" )
          print "- Loading fixture #{fixture_file}..."
          if File.size(dir) > 0
            ActiveRecord::Fixtures.create_fixtures(backup_path_db, fixture_file)
            puts "[DONE]".green
          else
            puts "[SKIPPING]".yellow
          end
        end
      end
    end

  end # namespace end: backup
end # namespace end: gitlab
