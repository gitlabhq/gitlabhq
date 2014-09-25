namespace :gitlab do
  namespace :cleanup do
    desc "GITLAB | Cleanup | Clean namespaces"
    task dirs: :environment  do
      warn_user_is_not_gitlab
      remove_flag = ENV['REMOVE']


      namespaces = Namespace.pluck(:path)
      git_base_path = Gitlab.config.gitlab_shell.repos_path
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

    desc "GITLAB | Cleanup | Clean repositories"
    task repos: :environment  do
      warn_user_is_not_gitlab
      remove_flag = ENV['REMOVE']

      git_base_path = Gitlab.config.gitlab_shell.repos_path
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

    desc "GITLAB | Cleanup | Block users that have been removed in LDAP"
    task block_removed_ldap_users: :environment  do
      warn_user_is_not_gitlab
      block_flag = ENV['BLOCK']

      User.ldap.each do |ldap_user|
        print "#{ldap_user.name} (#{ldap_user.extern_uid}) ..."
        if Gitlab::LDAP::Access.open { |access| access.allowed?(ldap_user) }
          puts " [OK]".green
        else
          if block_flag
            ldap_user.block!
            puts " [BLOCKED]".red
          else
            puts " [NOT IN LDAP]".yellow
          end
        end
      end

      unless block_flag
        puts "To block these users run this command with BLOCK=true".yellow
      end
    end
  end
end
