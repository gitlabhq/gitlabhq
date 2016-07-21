namespace :gitlab do
  namespace :cleanup do
    desc "GitLab | Cleanup | Clean namespaces"
    task dirs: :environment  do
      warn_user_is_not_gitlab
      remove_flag = ENV['REMOVE']

      namespaces = Namespace.pluck(:path)
      Gitlab.config.repositories.storages.each do |name, git_base_path|
        all_dirs = Dir.glob(git_base_path + '/*')

        puts git_base_path.color(:yellow)
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
            if FileUtils.rm_rf(dir_path)
              puts "Removed...#{dir_path}".color(:red)
            else
              puts "Cannot remove #{dir_path}".color(:red)
            end
          else
            puts "Can be removed: #{dir_path}".color(:red)
          end
        end
      end

      unless remove_flag
        puts "To cleanup this directories run this command with REMOVE=true".color(:yellow)
      end
    end

    desc "GitLab | Cleanup | Clean repositories"
    task repos: :environment  do
      warn_user_is_not_gitlab

      move_suffix = "+orphaned+#{Time.now.to_i}"
      Gitlab.config.repositories.storages.each do |name, repo_root|
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
    end

    desc "GitLab | Cleanup | Block users that have been removed in LDAP"
    task block_removed_ldap_users: :environment  do
      warn_user_is_not_gitlab
      block_flag = ENV['BLOCK']

      User.find_each do |user|
        next unless user.ldap_user?
        print "#{user.name} (#{user.ldap_identity.extern_uid}) ..."
        if Gitlab::LDAP::Access.allowed?(user)
          puts " [OK]".color(:green)
        else
          if block_flag
            user.block! unless user.blocked?
            puts " [BLOCKED]".color(:red)
          else
            puts " [NOT IN LDAP]".color(:yellow)
          end
        end
      end

      unless block_flag
        puts "To block these users run this command with BLOCK=true".color(:yellow)
      end
    end
  end
end
