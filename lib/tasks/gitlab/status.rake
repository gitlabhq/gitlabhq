namespace :gitlab do
  namespace :app do
    desc "GITLAB | Check gitlab installation status"
    task :status => :environment  do
      puts "Starting diagnostic"
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
        `git clone #{Gitlab.config.gitolite_admin_uri} /tmp/gitolite_gitlab_test`
        FileUtils.rm_rf("/tmp/gitolite_gitlab_test")
        print "Can clone gitolite-admin?............"
        puts "YES".green 
      rescue 
        print "Can clone gitolite-admin?............"
        puts "NO".red
        return
      end

      print "UMASK for .gitolite.rc is 0007? ............"
      unless open("#{git_base_path}/../.gitolite.rc").grep(/REPO_UMASK = 0007/).empty?
        puts "YES".green 
      else
        puts "NO".red
        return
      end

      puts "\nFinished"
    end
  end
end
