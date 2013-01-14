namespace :gitlab do
  namespace :cleanup do
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
      warn_user_is_not_gitlab
      remove_flag = ENV['REMOVE']


      namespaces = Namespace.pluck(:path)
      git_base_path = Gitlab.config.gitolite.repos_path
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
      end
    end
  end
end
