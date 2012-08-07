namespace :gitlab do
  namespace :app do
    desc "GITLAB | Check gitlab installation status"
    task :status => :environment  do
      puts "Starting diagnostic".yellow
      git_base_path = Gitlab.config.git_base_path

      print "config/database.yml............"
      if File.exists?(File.join Rails.root, "config", "database.yml") 
        puts "exists".green
      else 
        puts "missing".red
        return
      end

      print "config/gitlab.yml............"
      if File.exists?(File.join Rails.root, "config", "gitlab.yml")
        puts "exists".green 
      else
        puts "missing".red
        return
      end

      print "#{git_base_path}............"
      if File.exists?(git_base_path)  
        puts "exists".green 
      else 
        puts "missing".red
        return
      end

      print "#{git_base_path} is writable?............"
      if File.stat(git_base_path).writable?
        puts "YES".green 
      else
        puts "NO".red
        return
      end

      begin
        `git clone #{Gitlab::GitHost.admin_uri} /tmp/gitolite_gitlab_test`
        FileUtils.rm_rf("/tmp/gitolite_gitlab_test")
        print "Can clone gitolite-admin?............"
        puts "YES".green 
      rescue 
        print "Can clone gitolite-admin?............"
        puts "NO".red
        return
      end

      print "UMASK for .gitolite.rc is 0007? ............"
      unless open("#{git_base_path}/../.gitolite.rc").grep(/UMASK([ \t]*)=([ \t>]*)0007/).empty?
        puts "YES".green 
      else
        puts "NO".red
        return
      end

      if Project.count > 0 
        puts "Validating projects repositories:".yellow
        Project.find_each(:batch_size => 100) do |project|
          print "#{project.name}....."
          hook_file = File.join(project.path_to_repo, 'hooks','post-receive')

          unless File.exists?(hook_file)
            puts "post-receive file missing".red 
            next
          end


          unless File.owned?(hook_file)
            puts "post-receive file is not owner by gitlab".red 
            next
          end

          puts "post-reveice file ok".green
        end
      end

      puts "\nFinished".blue
    end
  end
end
