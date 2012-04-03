namespace :gitlab do
  namespace :app do
    desc "GITLAB | Check gitlab installation status"
    task :status => :environment  do
      puts "Starting diagnostic"

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

      GIT_HOST = YAML.load_file("#{Rails.root}/config/gitlab.yml")["git_host"]
      print "/home/git/repositories/............"
      if File.exists?(GIT_HOST['base_path'])  
        puts "exists".green 
      else 
        puts "missing".red
        return
      end

      print "/home/git/repositories/ is writable?............"
      if File.stat(GIT_HOST['base_path']).writable?
        puts "YES".green 
      else
        puts "NO".red
        return
      end

      begin
        `git clone #{GIT_HOST["admin_uri"]} /tmp/gitolite_gitlab_test`
        FileUtils.rm_rf("/tmp/gitolite_gitlab_test")
        print "Can clone gitolite-admin?............"
        puts "YES".green 
      rescue 
        print "Can clone gitolite-admin?............"
        puts "NO".red
        return
      end

      print "UMASK for .gitolite.rc is 0007? ............"
      unless open("#{GIT_HOST['base_path']}/../.gitolite.rc").grep(/REPO_UMASK = 0007/).empty?
        puts "YES".green 
      else
        puts "NO".red
        return
      end

      puts "\nFinished"
    end
  end
end
