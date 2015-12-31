namespace :gitlab do
  namespace :cleanup do
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
    desc "GitLab | Cleanup | Clean namespaces"
    task dirs: :environment  do
=======
=======
>>>>>>> origin/4-0-stable
=======
>>>>>>> gitlabhq/4-0-stable
    desc "GITLAB | Cleanup | Clean gitolite config"
    task :config => :environment  do
      warn_user_is_not_gitlab

      real_repos = Project.all.map(&:path_with_namespace)
      real_repos << "gitolite-admin"
      real_repos << "@all"

      remove_flag = ENV['REMOVE']

      puts "Looking for repositories to remove... "
      Gitlab::GitoliteConfig.new.apply do |config|
        all_repos = []
        garbage_repos = []

        all_repos = config.conf.repos.keys
        garbage_repos = all_repos - real_repos

        garbage_repos.each do |repo_name|
          if remove_flag
            config.conf.rm_repo(repo_name)
            print "to remove...".red
          end

          puts repo_name.red
        end
      end

      unless remove_flag
        puts "To cleanup repositories run this command with REMOVE=true".yellow
      end
    end

    desc "GITLAB | Cleanup | Clean namespaces"
    task :dirs => :environment  do
<<<<<<< HEAD
<<<<<<< HEAD
>>>>>>> gitlabhq/4-0-stable
=======
>>>>>>> origin/4-0-stable
=======
>>>>>>> gitlabhq/4-0-stable
      warn_user_is_not_gitlab
      remove_flag = ENV['REMOVE']


      namespaces = Namespace.pluck(:path)
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
      git_base_path = Gitlab.config.gitlab_shell.repos_path
=======
      git_base_path = Gitlab.config.gitolite.repos_path
>>>>>>> gitlabhq/4-0-stable
=======
      git_base_path = Gitlab.config.gitolite.repos_path
>>>>>>> origin/4-0-stable
=======
      git_base_path = Gitlab.config.gitolite.repos_path
>>>>>>> gitlabhq/4-0-stable
      all_dirs = Dir.glob(git_base_path + '/*')

      puts git_base_path.yellow
      puts "Looking for directories to remove... "

      all_dirs.reject! do |dir|
        # skip if git repo
        dir =~ /.git$/
      end

      all_dirs.reject! do |dir|
        dir_name = File.basename dir

        # skip if namespace present
        namespaces.include?(dir_name)
      end

      all_dirs.each do |dir_path|

        if remove_flag
          if FileUtils.rm_rf dir_path
            puts "Removed...#{dir_path}".red
          else
            puts "Cannot remove #{dir_path}".red
          end
        else
          puts "Can be removed: #{dir_path}".red
        end
      end

      unless remove_flag
        puts "To cleanup this directories run this command with REMOVE=true".yellow
      end
    end

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
    desc "GitLab | Cleanup | Clean repositories"
    task repos: :environment  do
      warn_user_is_not_gitlab

      move_suffix = "+orphaned+#{Time.now.to_i}"
      repo_root = Gitlab.config.gitlab_shell.repos_path
      # Look for global repos (legacy, depth 1) and normal repos (depth 2)
      IO.popen(%W(find #{repo_root} -mindepth 1 -maxdepth 2 -name *.git)) do |find|
        find.each_line do |path|
          path.chomp!
          repo_with_namespace = path.
            sub(repo_root, '').
            sub(%r{^/*}, '').
            chomp('.git').
            chomp('.wiki')
          next if Project.find_with_namespace(repo_with_namespace)
          new_path = path + move_suffix
          puts path.inspect + ' -> ' + new_path.inspect
          File.rename(path, new_path)
        end
      end
    end

    desc "GitLab | Cleanup | Block users that have been removed in LDAP"
    task block_removed_ldap_users: :environment  do
      warn_user_is_not_gitlab
      block_flag = ENV['BLOCK']

      User.find_each do |user|
        next unless user.ldap_user?
        print "#{user.name} (#{user.ldap_identity.extern_uid}) ..."
        if Gitlab::LDAP::Access.allowed?(user)
          puts " [OK]".green
        else
          if block_flag
            user.block! unless user.blocked?
            puts " [BLOCKED]".red
          else
            puts " [NOT IN LDAP]".yellow
          end
        end
      end

      unless block_flag
        puts "To block these users run this command with BLOCK=true".yellow
=======
=======
>>>>>>> origin/4-0-stable
=======
>>>>>>> gitlabhq/4-0-stable
    desc "GITLAB | Cleanup | Clean respositories"
    task :repos => :environment  do
      warn_user_is_not_gitlab
      remove_flag = ENV['REMOVE']

      git_base_path = Gitlab.config.gitolite.repos_path
      all_dirs = Dir.glob(git_base_path + '/*')

      global_projects = Project.where(namespace_id: nil).pluck(:path)

      puts git_base_path.yellow
      puts "Looking for global repos to remove... "

      # skip non git repo
      all_dirs.select! do |dir|
        dir =~ /.git$/
      end

      # skip existing repos
      all_dirs.reject! do |dir|
        repo_name = File.basename dir
        path = repo_name.gsub(/\.git$/, "")
        global_projects.include?(path)
      end

      # skip gitolite admin
      all_dirs.reject! do |dir|
        repo_name = File.basename dir
        repo_name == 'gitolite-admin.git'
      end


      all_dirs.each do |dir_path|
        if remove_flag
          if FileUtils.rm_rf dir_path
            puts "Removed...#{dir_path}".red
          else
            puts "Cannot remove #{dir_path}".red
          end
        else
          puts "Can be removed: #{dir_path}".red
        end
      end

      unless remove_flag
        puts "To cleanup this directories run this command with REMOVE=true".yellow
<<<<<<< HEAD
<<<<<<< HEAD
>>>>>>> gitlabhq/4-0-stable
=======
>>>>>>> origin/4-0-stable
=======
>>>>>>> gitlabhq/4-0-stable
      end
    end
  end
end
