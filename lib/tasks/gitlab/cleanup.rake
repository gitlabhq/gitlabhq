# Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/954
#
namespace :gitlab do
  namespace :cleanup do
    HASHED_REPOSITORY_NAME = '@hashed'.freeze

    desc "GitLab | Cleanup | Clean namespaces"
    task dirs: :gitlab_environment do
      warn_user_is_not_gitlab
      remove_flag = ENV['REMOVE']

      namespaces  = Namespace.pluck(:path)
      namespaces << HASHED_REPOSITORY_NAME  # add so that it will be ignored
      Gitlab.config.repositories.storages.each do |name, repository_storage|
        git_base_path = repository_storage.legacy_disk_path
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

    desc "GitLab | Cleanup | Delete moved repositories"
    task moved: :environment  do
      warn_user_is_not_gitlab
      remove_flag = ENV['REMOVE']

      Gitlab.config.repositories.storages.each do |name, repository_storage|
        repo_root = repository_storage.legacy_disk_path.chomp('/')
        # Look for global repos (legacy, depth 1) and normal repos (depth 2)
        IO.popen(%W(find #{repo_root} -mindepth 1 -maxdepth 2 -name *+moved*.git)) do |find|
          find.each_line do |path|
            path.chomp!

            if remove_flag
              if FileUtils.rm_rf(path)
                puts "Removed...#{path}".color(:green)
              else
                puts "Cannot remove #{path}".color(:red)
              end
            else
              puts "Can be removed: #{path}".color(:green)
            end
          end
        end
      end

      unless remove_flag
        puts "To cleanup these repositories run this command with REMOVE=true".color(:yellow)
      end
    end

    desc "GitLab | Cleanup | Clean repositories"
    task repos: :gitlab_environment do
      warn_user_is_not_gitlab

      move_suffix = "+orphaned+#{Time.now.to_i}"
      Gitlab.config.repositories.storages.each do |name, repository_storage|
        repo_root = repository_storage.legacy_disk_path
        # Look for global repos (legacy, depth 1) and normal repos (depth 2)
        IO.popen(%W(find #{repo_root} -mindepth 1 -maxdepth 2 -name *.git)) do |find|
          find.each_line do |path|
            path.chomp!
            repo_with_namespace = path
              .sub(repo_root, '')
              .sub(%r{^/*}, '')
              .chomp('.git')
              .chomp('.wiki')

            # TODO ignoring hashed repositories for now.  But revisit to fully support
            # possible orphaned hashed repos
            next if repo_with_namespace.start_with?("#{HASHED_REPOSITORY_NAME}/") || Project.find_by_full_path(repo_with_namespace)

            new_path = path + move_suffix
            puts path.inspect + ' -> ' + new_path.inspect
            File.rename(path, new_path)
          end
        end
      end
    end

    desc "GitLab | Cleanup | Block users that have been removed in LDAP"
    task block_removed_ldap_users: :gitlab_environment do
      warn_user_is_not_gitlab
      block_flag = ENV['BLOCK']

      User.find_each do |user|
        next unless user.ldap_user?

        print "#{user.name} (#{user.ldap_identity.extern_uid}) ..."

        if Gitlab::Auth::LDAP::Access.allowed?(user)
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

    # This is a rake task which removes faulty refs. These refs where only
    # created in the 8.13.RC cycle, and fixed in the stable builds which were
    # released. So likely this should only be run once on gitlab.com
    # Faulty refs are moved so they are kept around, else some features break.
    desc 'GitLab | Cleanup | Remove faulty deployment refs'
    task move_faulty_deployment_refs: :gitlab_environment do
      projects = Project.where(id: Deployment.select(:project_id).distinct)

      projects.find_each do |project|
        rugged = project.repository.rugged

        max_iid = project.deployments.maximum(:iid)

        rugged.references.each('refs/environments/**/*') do |ref|
          id = ref.name.split('/').last.to_i
          next unless id > max_iid

          project.deployments.find(id).create_ref
          project.repository.delete_refs(ref)
        end
      end
    end
  end
end
