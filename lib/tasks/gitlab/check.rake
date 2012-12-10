namespace :gitlab do
  desc "GITLAB | Check the configuration of GitLab and its environment"
  task check: %w{gitlab:env:check
                 gitlab:app:check
                 gitlab:gitolite:check
                 gitlab:resque:check}

  namespace :app do
    desc "GITLAB | Check the configuration of the GitLab Rails app"
    task check: :environment  do

      print "config/database.yml............"
      if File.exists?(Rails.root.join "config", "database.yml")
        puts "exists".green
      else
        puts "missing".red
        return
      end

      print "config/gitlab.yml............"
      if File.exists?(Rails.root.join "config", "gitlab.yml")
        puts "exists".green
      else
        puts "missing".red
        return
      end
    end
  end

  namespace :env do
    desc "GITLAB | Check the configuration of the environment"
    task check: :environment  do
    end
  end

  namespace :gitolite do
    desc "GITLAB | Check the configuration of Gitolite"
    task check: :environment  do
      git_base_path = Gitlab.config.git_base_path

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

      FileUtils.rm_rf("/tmp/gitolite_gitlab_test")
      begin
        `git clone -q #{Gitlab.config.gitolite_admin_uri} /tmp/gitolite_gitlab_test`
        raise unless $?.success?
        print "Can clone gitolite-admin?............"
        puts "YES".green
      rescue
        print "Can clone gitolite-admin?............"
        puts "NO".red
        return
      end

      begin
        Dir.chdir("/tmp/gitolite_gitlab_test") do
          `touch blah && git add blah && git commit -qm blah -- blah`
          raise unless $?.success?
        end
        print "Can git commit?............"
        puts "YES".green
      rescue
        print "Can git commit?............"
        puts "NO".red
        return
      ensure
        FileUtils.rm_rf("/tmp/gitolite_gitlab_test")
      end

      print "UMASK for .gitolite.rc is 0007? ............"
      if open(File.absolute_path("#{git_base_path}/../.gitolite.rc")).grep(/UMASK([ \t]*)=([ \t>]*)0007/).any?
        puts "YES".green
      else
        puts "NO".red
        return
      end

      gitolite_hooks_path = File.join(Gitlab.config.git_hooks_path, "common")
      gitlab_hook_files = ['post-receive']
      gitlab_hook_files.each do |file_name|
        dest = File.join(gitolite_hooks_path, file_name)
        print "#{dest} exists? ............"
        if File.exists?(dest)
          puts "YES".green
        else
          puts "NO".red
          return
        end
      end

      if Project.count > 0
        puts "\nValidating projects repositories:".yellow
        Project.find_each(:batch_size => 100) do |project|
          print "* #{project.name}....."
          hook_file = File.join(project.path_to_repo, 'hooks', 'post-receive')

          unless File.exists?(hook_file)
            puts "post-receive file missing".red
            next
          end

          original_content = File.read(Rails.root.join('lib', 'hooks', 'post-receive'))
          new_content = File.read(hook_file)

          if original_content == new_content
            puts "post-receive file ok".green
          else
            puts "post-receive file content does not match".red
          end
        end
      end
    end
  end

  namespace :resque do
    desc "GITLAB | Check the configuration of Resque"
    task check: :environment  do
    end
  end
end
