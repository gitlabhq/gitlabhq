# Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/954
#
namespace :gitlab do
  namespace :cleanup do
    HASHED_REPOSITORY_NAME = '@hashed'.freeze

    desc "GitLab | Cleanup | Clean namespaces"
    task dirs: :gitlab_environment do
      warn_user_is_not_gitlab

      namespaces = Namespace.pluck(:path)
      namespaces << HASHED_REPOSITORY_NAME  # add so that it will be ignored
      Gitlab.config.repositories.storages.each do |name, repository_storage|
        git_base_path = Gitlab::GitalyClient::StorageSettings.allow_disk_access { repository_storage.legacy_disk_path }
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
          if remove?
            if FileUtils.rm_rf dir_path
              puts "Removed...#{dir_path}".color(:red)
            else
              puts "Cannot remove #{dir_path}".color(:red)
            end
          else
            puts "Can be removed: #{dir_path}".color(:red)
          end
        end
      end

      unless remove?
        puts "To cleanup this directories run this command with REMOVE=true".color(:yellow)
      end
    end

    desc "GitLab | Cleanup | Clean repositories"
    task repos: :gitlab_environment do
      warn_user_is_not_gitlab

      move_suffix = "+orphaned+#{Time.now.to_i}"
      Gitlab.config.repositories.storages.each do |name, repository_storage|
        repo_root = Gitlab::GitalyClient::StorageSettings.allow_disk_access { repository_storage.legacy_disk_path }

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

    desc "GitLab | Cleanup | Clean orphaned project uploads"
    task project_uploads: :gitlab_environment do
      warn_user_is_not_gitlab

      cleaner = Gitlab::Cleanup::ProjectUploads.new(logger: logger)
      cleaner.run!(dry_run: dry_run?)

      if dry_run?
        logger.info "To clean up these files run this command with DRY_RUN=false".color(:yellow)
      end
    end

    desc 'GitLab | Cleanup | Clean orphan remote upload files that do not exist in the db'
    task remote_upload_files: :environment do
      cleaner = Gitlab::Cleanup::RemoteUploads.new(logger: logger)
      cleaner.run!(dry_run: dry_run?)

      if dry_run?
        logger.info "To cleanup these files run this command with DRY_RUN=false".color(:yellow)
      end
    end

    def remove?
      ENV['REMOVE'] == 'true'
    end

    def dry_run?
      ENV['DRY_RUN'] != 'false'
    end

    def logger
      return @logger if defined?(@logger)

      @logger = if Rails.env.development? || Rails.env.production?
                  Logger.new(STDOUT).tap do |stdout_logger|
                    stdout_logger.extend(ActiveSupport::Logger.broadcast(Rails.logger))
                  end
                else
                  Rails.logger
                end
    end
  end
end
