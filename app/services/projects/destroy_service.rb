# frozen_string_literal: true

module Projects
  class DestroyService < BaseService
    include Gitlab::ShellAdapter

    DestroyError = Class.new(StandardError)

    def async_execute
      project.update_attribute(:pending_delete, true)

      # Ensure no repository +deleted paths are kept,
      # regardless of any issue with the ProjectDestroyWorker
      # job process.
      schedule_stale_repos_removal

      job_id = ProjectDestroyWorker.perform_async(project.id, current_user.id, params)
      log_info("User #{current_user.id} scheduled destruction of project #{project.full_path} with job ID #{job_id}")
    end

    def execute
      return false unless can?(current_user, :remove_project, project)

      project.update_attribute(:pending_delete, true)
      # Flush the cache for both repositories. This has to be done _before_
      # removing the physical repositories as some expiration code depends on
      # Git data (e.g. a list of branch names).
      flush_caches(project)

      if Feature.enabled?(:abort_deleted_project_pipelines, default_enabled: :yaml)
        ::Ci::AbortPipelinesService.new.execute(project.all_pipelines, :project_deleted)
      end

      Projects::UnlinkForkService.new(project, current_user).execute

      attempt_destroy(project)

      system_hook_service.execute_hooks_for(project, :destroy)
      log_info("Project \"#{project.full_path}\" was deleted")

      current_user.invalidate_personal_projects_count

      true
    rescue StandardError => error
      attempt_rollback(project, error.message)
      false
    rescue Exception => error # rubocop:disable Lint/RescueException
      # Project.transaction can raise Exception
      attempt_rollback(project, error.message)
      raise
    end

    private

    def trash_project_repositories!
      unless remove_repository(project.repository)
        raise_error(s_('DeleteProject|Failed to remove project repository. Please try again or contact administrator.'))
      end

      unless remove_repository(project.wiki.repository)
        raise_error(s_('DeleteProject|Failed to remove wiki repository. Please try again or contact administrator.'))
      end
    end

    def trash_relation_repositories!
      unless remove_snippets
        raise_error(s_('DeleteProject|Failed to remove project snippets. Please try again or contact administrator.'))
      end
    end

    def remove_snippets
      response = ::Snippets::BulkDestroyService.new(current_user, project.snippets).execute

      response.success?
    end

    def remove_repository(repository)
      return true unless repository

      result = Repositories::DestroyService.new(repository).execute

      result[:status] == :success
    end

    def schedule_stale_repos_removal
      repos = [project.repository, project.wiki.repository]

      repos.each do |repository|
        next unless repository

        Repositories::ShellDestroyService.new(repository).execute(Repositories::ShellDestroyService::STALE_REMOVAL_DELAY)
      end
    end

    def attempt_rollback(project, message)
      return unless project

      # It's possible that the project was destroyed, but some after_commit
      # hook failed and caused us to end up here. A destroyed model will be a frozen hash,
      # which cannot be altered.
      project.update(delete_error: message, pending_delete: false) unless project.destroyed?

      log_error("Deletion failed on #{project.full_path} with the following message: #{message}")
    end

    def attempt_destroy(project)
      unless remove_registry_tags
        raise_error(s_('DeleteProject|Failed to remove some tags in project container registry. Please try again or contact administrator.'))
      end

      project.leave_pool_repository
      destroy_project_related_records(project)
    end

    def destroy_project_related_records(project)
      log_destroy_event
      trash_relation_repositories!
      trash_project_repositories!
      destroy_web_hooks!

      # Rails attempts to load all related records into memory before
      # destroying: https://github.com/rails/rails/issues/22510
      # This ensures we delete records in batches.
      #
      # Exclude container repositories because its before_destroy would be
      # called multiple times, and it doesn't destroy any database records.
      project.destroy_dependent_associations_in_batches(exclude: [:container_repositories, :snippets])
      project.destroy!
    end

    def log_destroy_event
      log_info("Attempting to destroy #{project.full_path} (#{project.id})")
    end

    # The project can have multiple webhooks with hundreds of thousands of web_hook_logs.
    # By default, they are removed with "DELETE CASCADE" option defined via foreign_key.
    # But such queries can exceed the statement_timeout limit and fail to delete the project.
    # (see https://gitlab.com/gitlab-org/gitlab/-/issues/26259)
    #
    # To prevent that we use WebHooks::DestroyService. It deletes logs in batches and
    # produces smaller and faster queries to the database.
    def destroy_web_hooks!
      project.hooks.find_each do |web_hook|
        result = ::WebHooks::DestroyService.new(current_user).sync_destroy(web_hook)

        unless result[:status] == :success
          raise_error(s_('DeleteProject|Failed to remove webhooks. Please try again or contact administrator.'))
        end
      end
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
      raise DestroyError, message
    end

    def flush_caches(project)
      Projects::ForksCountService.new(project).delete_cache
    end
  end
end

Projects::DestroyService.prepend_mod_with('Projects::DestroyService')
