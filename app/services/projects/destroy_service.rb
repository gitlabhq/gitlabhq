module Projects
  class DestroyService < BaseService
    include Gitlab::ShellAdapter

    DELETED_FLAG = '+deleted'

    DestroyError = Class.new(StandardError)

    Executor = Struct.new(:service, :project) do
      def execute
        project.team.truncate

        repo_path = project.path_with_namespace
        wiki_path = repo_path + '.wiki'

        # Flush the cache for both repositories. This has to be done _before_
        # removing the physical repositories as some expiration code depends on
        # Git data (e.g. a list of branch names).
        flush_caches(wiki_path)

        Projects::UnlinkForkService.new(project, service.current_user).execute

        project.destroy!

        unless remove_registry_tags
          raise_error('Failed to remove project container registry')
        end

        unless remove_repository(repo_path)
          raise_error('Failed to remove project repository')
        end

        unless remove_repository(wiki_path)
          raise_error('Failed to remove wiki repository')
        end

        service.log_info(
          "Project \"#{project.path_with_namespace}\" was removed")
        service.system_hook_service.execute_hooks_for(project, :destroy)

        true
      end

      private

      def flush_caches(wiki_path)
        project.repository.before_delete

        Repository.new(wiki_path, project).before_delete
      end

      def remove_registry_tags
        return true unless Gitlab.config.registry.enabled

        project.container_registry_repository.delete_tags
      end

      def remove_repository(path)
        # Skip repository removal. We use this flag when remove user or group
        return true if service.params[:skip_repo] == true

        # There is a possibility project does not have repository or wiki
        return true unless
          service.gitlab_shell.exists?(
            project.repository_storage_path, path + '.git')

        new_path = removal_path(path)

        if service.gitlab_shell.mv_repository(
          project.repository_storage_path, path, new_path)
          service.log_info("Repository \"#{path}\" moved to \"#{new_path}\"")
          GitlabShellWorker.perform_in(
            5.minutes,
            :remove_repository,
            project.repository_storage_path,
            new_path)
        else
          false
        end
      end

      def raise_error(message)
        raise DestroyError.new(
          "#{message}. Please try again or contact administrator")
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
    end

    def async_execute
      project.update_attribute(:pending_delete, true)
      job_id = ProjectDestroyWorker.perform_async(project.id, current_user.id, params)
      Rails.logger.info("User #{current_user.id} scheduled destruction of project #{project.path_with_namespace} with job ID #{job_id}")
    end

    def execute
      return false unless can?(current_user, :remove_project, project)

      Gitlab::OptimisticLocking.retry_lock(project) do |subject|
        Executor.new(self, subject).execute
      end

      true
    end
  end
end
