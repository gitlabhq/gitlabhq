module Projects
  class DestroyService < BaseService
    include Gitlab::ShellAdapter
    prepend ::EE::Projects::DestroyService

    DestroyError = Class.new(StandardError)

    DELETED_FLAG = '+deleted'.freeze

    def async_execute
      project.update_attribute(:pending_delete, true)
      job_id = ProjectDestroyWorker.perform_async(project.id, current_user.id, params)
      Rails.logger.info("User #{current_user.id} scheduled destruction of project #{project.full_path} with job ID #{job_id}")
    end

    def execute
      return false unless can?(current_user, :remove_project, project)

      # Flush the cache for both repositories. This has to be done _before_
      # removing the physical repositories as some expiration code depends on
      # Git data (e.g. a list of branch names).
      flush_caches(project)

      Projects::UnlinkForkService.new(project, current_user).execute

      # The project is not necessarily a fork, so update the fork network originating
      # from this project
      if fork_network = project.root_of_fork_network
        fork_network.update(root_project: nil,
                            deleted_root_project_name: project.full_name)
      end

      attempt_destroy_transaction(project)

      system_hook_service.execute_hooks_for(project, :destroy)
      log_info("Project \"#{project.full_path}\" was removed")

      current_user.invalidate_personal_projects_count

      true
    rescue => error
      attempt_rollback(project, error.message)
      false
    rescue Exception => error # rubocop:disable Lint/RescueException
      # Project.transaction can raise Exception
      attempt_rollback(project, error.message)
      raise
    end

    def attempt_repositories_rollback
      return unless @project

      flush_caches(@project)

      unless mv_repository(removal_path(repo_path), repo_path)
        raise_error('Failed to restore project repository. Please contact the administrator.')
      end

      unless mv_repository(removal_path(wiki_path), wiki_path)
        raise_error('Failed to restore wiki repository. Please contact the administrator.')
      end
    end

    private

    def repo_path
      project.disk_path
    end

    def wiki_path
      project.wiki.disk_path
    end

    def trash_repositories!
      unless remove_repository(repo_path)
        raise_error('Failed to remove project repository. Please try again or contact administrator.')
      end

      unless remove_repository(wiki_path)
        raise_error('Failed to remove wiki repository. Please try again or contact administrator.')
      end
    end

    def remove_repository(path)
      # Skip repository removal. We use this flag when remove user or group
      return true if params[:skip_repo] == true

      new_path = removal_path(path)

      if mv_repository(path, new_path)
        log_info("Repository \"#{path}\" moved to \"#{new_path}\"")

        project.run_after_commit do
          # self is now project
          GitlabShellWorker.perform_in(5.minutes, :remove_repository, self.repository_storage_path, new_path)
        end
      else
        false
      end
    end

    def mv_repository(from_path, to_path)
      # There is a possibility project does not have repository or wiki
      return true unless gitlab_shell.exists?(project.repository_storage_path, from_path + '.git')

      gitlab_shell.mv_repository(project.repository_storage_path, from_path, to_path)
    end

    def attempt_rollback(project, message)
      return unless project

      # It's possible that the project was destroyed, but some after_commit
      # hook failed and caused us to end up here. A destroyed model will be a frozen hash,
      # which cannot be altered.
      project.update_attributes(delete_error: message, pending_delete: false) unless project.destroyed?

      log_error("Deletion failed on #{project.full_path} with the following message: #{message}")
    end

    def attempt_destroy_transaction(project)
      Project.transaction do
        unless remove_legacy_registry_tags
          raise_error('Failed to remove some tags in project container registry. Please try again or contact administrator.')
        end

        trash_repositories!

        project.team.truncate
        project.destroy!
      end
    end

    ##
    # This method makes sure that we correctly remove registry tags
    # for legacy image repository (when repository path equals project path).
    #
    def remove_legacy_registry_tags
      return true unless Gitlab.config.registry.enabled

      ContainerRepository.build_root_repository(project).tap do |repository|
        return repository.has_tags? ? repository.delete_tags! : true
      end
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

    def flush_caches(project)
      project.repository.before_delete

      Repository.new(wiki_path, project, disk_path: repo_path).before_delete

      Projects::ForksCountService.new(project).delete_cache
    end
  end
end
