module Projects
  class DestroyService < BaseService
    include Gitlab::ShellAdapter

    class DestroyError < StandardError; end

    DELETED_FLAG = '+deleted'

    def async_execute
      project.transaction do
        project.update_attribute(:pending_delete, true)
        job_id = ProjectDestroyWorker.perform_async(project.id, current_user.id, params)
        Rails.logger.info("User #{current_user.id} scheduled destruction of project #{project.path_with_namespace} with job ID #{job_id}")
      end
    end

    def execute
      return false unless can?(current_user, :remove_project, project)

      project.team.truncate

      # Flush the cache for both repositories. This has to be done _before_
      # removing the physical repositories as some expiration code depends on
      # Git data (e.g. a list of branch names).
      flush_caches(project, wiki_path)

      Project.transaction do
        project.destroy!
        trash_repositories!

        unless remove_registry_tags
          raise_error('Failed to remove project container registry. Please try again or contact administrator')
        end
      end

      log_info("Project \"#{project.path_with_namespace}\" was removed")
      system_hook_service.execute_hooks_for(project, :destroy)
      true
    end

    # Removes physical repository in a Geo replicated secondary node
    # There is no need to do any database operation as it will be
    # replicated by itself.
    def geo_replicate
      # Flush the cache for both repositories. This has to be done _before_
      # removing the physical repositories as some expiration code depends on
      # Git data (e.g. a list of branch names).
      flush_caches(project, wiki_path)

      trash_repositories!
      log_info("Project \"#{project.name}\" was removed")
    end

    private

    def repo_path
      project.path_with_namespace
    end

    def wiki_path
      repo_path + '.wiki'
    end

    def trash_repositories!
      unless remove_repository(repo_path)
        raise_error('Failed to remove project repository. Please try again or contact administrator')
      end

      unless remove_repository(wiki_path)
        raise_error('Failed to remove wiki repository. Please try again or contact administrator')
      end
    end

    def remove_repository(path)
      # Skip repository removal. We use this flag when remove user or group
      return true if params[:skip_repo] == true

      # There is a possibility project does not have repository or wiki
      return true unless gitlab_shell.exists?(project.repository_storage_path, path + '.git')

      new_path = removal_path(path)

      if gitlab_shell.mv_repository(project.repository_storage_path, path, new_path)
        log_info("Repository \"#{path}\" moved to \"#{new_path}\"")
        GitlabShellWorker.perform_in(5.minutes, :remove_repository, project.repository_storage_path, new_path)
      else
        false
      end
    end

    def remove_registry_tags
      return true unless Gitlab.config.registry.enabled

      project.container_registry_repository.delete_tags
    end

    def raise_error(message)
      raise DestroyError.new(message)
    end

    # Build a path for removing repositories
    # We use `+` because its not allowed by GitLab so user can not create
    # project with name cookies+119+deleted and capture someone stalled repository
    #
    # gitlab/cookies.git -> gitlab/cookies+119+deleted.git
    #
    def removal_path(path)
      "#{path}+#{project.id}#{DELETED_FLAG}"
    end

    def flush_caches(project, wiki_path)
      project.repository.before_delete

      Repository.new(wiki_path, project).before_delete
    end
  end
end
