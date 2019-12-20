# frozen_string_literal: true

module Projects
  class DestroyService < BaseService
    include Gitlab::ShellAdapter

    DestroyError = Class.new(StandardError)

    DELETED_FLAG = '+deleted'
    REPO_REMOVAL_DELAY = 5.minutes.to_i

    def async_execute
      project.update_attribute(:pending_delete, true)

      # Ensure no repository +deleted paths are kept,
      # regardless of any issue with the ProjectDestroyWorker
      # job process.
      schedule_stale_repos_removal

      job_id = ProjectDestroyWorker.perform_async(project.id, current_user.id, params)
      Rails.logger.info("User #{current_user.id} scheduled destruction of project #{project.full_path} with job ID #{job_id}") # rubocop:disable Gitlab/RailsLogger
    end

    def execute
      return false unless can?(current_user, :remove_project, project)

      # Flush the cache for both repositories. This has to be done _before_
      # removing the physical repositories as some expiration code depends on
      # Git data (e.g. a list of branch names).
      flush_caches(project)

      Projects::UnlinkForkService.new(project, current_user).execute

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

      unless rollback_repository(removal_path(repo_path), repo_path)
        raise_error(s_('DeleteProject|Failed to restore project repository. Please contact the administrator.'))
      end

      unless rollback_repository(removal_path(wiki_path), wiki_path)
        raise_error(s_('DeleteProject|Failed to restore wiki repository. Please contact the administrator.'))
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
        raise_error(s_('DeleteProject|Failed to remove project repository. Please try again or contact administrator.'))
      end

      unless remove_repository(wiki_path)
        raise_error(s_('DeleteProject|Failed to remove wiki repository. Please try again or contact administrator.'))
      end
    end

    def remove_repository(path)
      # There is a possibility project does not have repository or wiki
      return true unless repo_exists?(path)

      new_path = removal_path(path)

      if mv_repository(path, new_path)
        log_info(%Q{Repository "#{path}" moved to "#{new_path}" for project "#{project.full_path}"})

        project.run_after_commit do
          GitlabShellWorker.perform_in(REPO_REMOVAL_DELAY, :remove_repository, self.repository_storage, new_path)
        end
      else
        false
      end
    end

    def schedule_stale_repos_removal
      repo_paths = [removal_path(repo_path), removal_path(wiki_path)]

      # Ideally it should wait until the regular removal phase finishes,
      # so let's delay it a bit further.
      repo_paths.each do |path|
        GitlabShellWorker.perform_in(REPO_REMOVAL_DELAY * 2, :remove_repository, project.repository_storage, path)
      end
    end

    def rollback_repository(old_path, new_path)
      # There is a possibility project does not have repository or wiki
      return true unless repo_exists?(old_path)

      mv_repository(old_path, new_path)
    end

    def repo_exists?(path)
      gitlab_shell.repository_exists?(project.repository_storage, path + '.git')
    end

    def mv_repository(from_path, to_path)
      return true unless repo_exists?(from_path)

      gitlab_shell.mv_repository(project.repository_storage, from_path, to_path)
    end

    def attempt_rollback(project, message)
      return unless project

      # It's possible that the project was destroyed, but some after_commit
      # hook failed and caused us to end up here. A destroyed model will be a frozen hash,
      # which cannot be altered.
      project.update(delete_error: message, pending_delete: false) unless project.destroyed?

      log_error("Deletion failed on #{project.full_path} with the following message: #{message}")
    end

    def attempt_destroy_transaction(project)
      unless remove_registry_tags
        raise_error(s_('DeleteProject|Failed to remove some tags in project container registry. Please try again or contact administrator.'))
      end

      project.leave_pool_repository

      Project.transaction do
        log_destroy_event
        trash_repositories!

        # Rails attempts to load all related records into memory before
        # destroying: https://github.com/rails/rails/issues/22510
        # This ensures we delete records in batches.
        #
        # Exclude container repositories because its before_destroy would be
        # called multiple times, and it doesn't destroy any database records.
        project.destroy_dependent_associations_in_batches(exclude: [:container_repositories])
        project.destroy!
      end
    end

    def log_destroy_event
      log_info("Attempting to destroy #{project.full_path} (#{project.id})")
    end

    def remove_registry_tags
      return true unless Gitlab.config.registry.enabled
      return false unless remove_legacy_registry_tags

      project.container_repositories.find_each do |container_repository|
        service = Projects::ContainerRepository::DestroyService.new(project, current_user)
        service.execute(container_repository)
      end

      true
    end

    ##
    # This method makes sure that we correctly remove registry tags
    # for legacy image repository (when repository path equals project path).
    #
    def remove_legacy_registry_tags
      return true unless Gitlab.config.registry.enabled

      ::ContainerRepository.build_root_repository(project).tap do |repository|
        break repository.has_tags? ? repository.delete_tags! : true
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
      ignore_git_errors(repo_path) { project.repository.before_delete }

      ignore_git_errors(wiki_path) { Repository.new(wiki_path, project, disk_path: repo_path).before_delete }

      Projects::ForksCountService.new(project).delete_cache
    end

    # If we get a Gitaly error, the repository may be corrupted. We can
    # ignore these errors since we're going to trash the repositories
    # anyway.
    def ignore_git_errors(disk_path, &block)
      yield
    rescue Gitlab::Git::CommandError => e
      Gitlab::GitLogger.warn(class: self.class.name, project_id: project.id, disk_path: disk_path, message: e.to_s)
    end
  end
end

Projects::DestroyService.prepend_if_ee('EE::Projects::DestroyService')
