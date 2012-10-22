require 'active_record/fixtures'

namespace :gitlab do
  namespace :app do
    # Create backup of GitLab system
    desc "GITLAB | Create a backup of the GitLab system"
    task :backup_create => :environment do
      Rake::Task["gitlab:app:db_dump"].invoke
      Rake::Task["gitlab:app:repo_dump"].invoke

      Dir.chdir(Gitlab.config.backup_path)

      # saving additional informations
      s = {}
      s[:db_version]         = "#{ActiveRecord::Migrator.current_version}"
      s[:backup_created_at]  = "#{Time.now}"
      s[:gitlab_version]     = %x{git rev-parse HEAD}.gsub(/\n/,"")
      s[:tar_version]        = %x{tar --version | head -1}.gsub(/\n/,"")

      File.open("#{Gitlab.config.backup_path}/backup_information.yml", "w+") do |file|
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
      if Gitlab.config.backup_keep_time > 0
        file_list = Dir.glob("*_gitlab_backup.tar").map { |f| f.split(/_/).first.to_i }
        file_list.sort.each do |timestamp|
          if Time.at(timestamp) < (Time.now - Gitlab.config.backup_keep_time)
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
    task :backup_restore => :environment do
      Dir.chdir(Gitlab.config.backup_path)

      # check for existing backups in the backup dir
      file_list = Dir.glob("*_gitlab_backup.tar").each.map { |f| f.split(/_/).first.to_i }
      puts "no backups found" if file_list.count == 0
      if file_list.count > 1 && ENV["BACKUP"].nil?
        puts "Found more than one backup, please specify which one you want to restore:"
        puts "rake gitlab:app:backup_restore BACKUP=timestamp_of_backup"
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
      ENV["VERSION"] = "#{settings["db_version"]}" if settings["db_version"].to_i > 0

      # restoring mismatching backups can lead to unexpected problems
      if settings["gitlab_version"] != %x{git rev-parse HEAD}.gsub(/\n/,"")
        puts "gitlab_version mismatch:".red
        puts "  Your current HEAD differs from the HEAD in the backup!".red
        puts "  Please switch to the following revision and try again:".red
        puts "  revision: #{settings["gitlab_version"]}".red
        exit 1
      end

      Rake::Task["gitlab:app:db_restore"].invoke
      Rake::Task["gitlab:app:repo_restore"].invoke

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

    task :repo_dump => :environment do
      backup_path_repo = File.join(Gitlab.config.backup_path, "repositories")
      FileUtils.mkdir_p(backup_path_repo) until Dir.exists?(backup_path_repo)
      puts "Dumping repositories:"
      project = Project.all.map { |n| [n.path, n.path_to_repo] }
      project << ["gitolite-admin.git", File.join(File.dirname(project.first.second), "gitolite-admin.git")]
      project.each do |project|
        print "- Dumping repository #{project.first}... "
        if Kernel.system("cd #{project.second} > /dev/null 2>&1 && git bundle create #{backup_path_repo}/#{project.first}.bundle --all > /dev/null 2>&1")
          puts "[DONE]".green
        else
          puts "[FAILED]".red
        end
      end
    end

    task :repo_restore => :environment do
      backup_path_repo = File.join(Gitlab.config.backup_path, "repositories")
      puts "Restoring repositories:"
      project = Project.all.map { |n| [n.path, n.path_to_repo] }
      project << ["gitolite-admin.git", File.join(File.dirname(project.first.second), "gitolite-admin.git")]
      project.each do |project|
        print "- Restoring repository #{project.first}... "
        FileUtils.rm_rf(project.second) if File.dirname(project.second) # delete old stuff
        if Kernel.system("cd #{File.dirname(project.second)} > /dev/null 2>&1 && git clone --bare #{backup_path_repo}/#{project.first}.bundle #{project.first}.git > /dev/null 2>&1")
          permission_commands = [
            "sudo chmod -R g+rwX #{Gitlab.config.git_base_path}",
            "sudo chown -R #{Gitlab.config.ssh_user}:#{Gitlab.config.ssh_user} #{Gitlab.config.git_base_path}"
          ]
          permission_commands.each { |command| Kernel.system(command) }
          puts "[DONE]".green
        else
          puts "[FAILED]".red
        end
      end
    end

    ###################################### DB ######################################

    task :db_dump => :environment do
      backup_path_db = File.join(Gitlab.config.backup_path, "db")
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

    task :db_restore=> :environment do
      backup_path_db = File.join(Gitlab.config.backup_path, "db")

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

  end # namespace end: app
end # namespace end: gitlab
