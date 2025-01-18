# frozen_string_literal: true

module Projects
  class DestroyService < BaseService
    include Gitlab::ShellAdapter

    DestroyError = Class.new(StandardError)
    BATCH_SIZE = 100

    def async_execute
      project.update_attribute(:pending_delete, true)

      job_id = ProjectDestroyWorker.perform_async(project.id, current_user.id, params)
      log_info("User #{current_user.id} scheduled destruction of project #{project.full_path} with job ID #{job_id}")
    end

    def execute
      unless can?(current_user, :remove_project, project)
        project.update_attribute(:pending_delete, false) if project.pending_delete?
        return false
      end

      project.update_attribute(:pending_delete, true)

      # There is a possibility of active repository move processes for
      # project and snippets. An attempt to delete the project at the same time
      # can lead to race condition and an inconsistent state.
      #
      # This validation stops the project delete process if it detects active
      # repository move schedules for it.
      validate_active_repositories_move!

      # Flush the cache for both repositories. This has to be done _before_
      # removing the physical repositories as some expiration code depends on
      # Git data (e.g. a list of branch names).
      flush_caches(project)

      ::Ci::AbortPipelinesService.new.execute(all_pipelines, :project_deleted)

      Projects::UnlinkForkService.new(project, current_user).execute(refresh_statistics: false)

      attempt_destroy(project)

      execute_hooks(project)

      Gitlab::AppLogger.info(
        class: self.class.name,
        message: "Project \"#{project.full_path}\" was deleted",
        project_id: project.id,
        full_path: project.full_path
      )

      publish_project_deleted_event_for(project)

      project.invalidate_personal_projects_count_of_owner

      true
    rescue StandardError => error
      context = Gitlab::ApplicationContext.current.merge(project_id: project.id)
      Gitlab::ErrorTracking.track_exception(error, **context)
      attempt_rollback(project, error.message)
      false
    rescue Exception => error # rubocop:disable Lint/RescueException
      # Project.transaction can raise Exception
      attempt_rollback(project, error.message)
      raise
    end

    private

    def all_pipelines
      # We don't use `Project#all_pipelines` to skip the `build_enabled?` setting in order to get all pipelines.
      ::Ci::Pipeline.for_project(project.id)
    end

    def validate_active_repositories_move!
      if project.repository_storage_moves.scheduled_or_started.exists?
        raise_error(s_("DeleteProject|Couldn't remove the project. A project repository storage move is in progress. Try again when it's complete."))
      end

      if ::ProjectSnippet.by_project(project).with_repository_storage_moves.merge(::Snippets::RepositoryStorageMove.scheduled_or_started).exists?
        raise_error(s_("DeleteProject|Couldn't remove the project. A related snippet repository storage move is in progress. Try again when it's complete."))
      end
    end

    def trash_project_repositories!
      unless remove_repository(project.repository)
        raise_error(s_('DeleteProject|Failed to remove project repository. Please try again or contact administrator.'))
      end

      unless remove_repository(project.wiki.repository)
        raise_error(s_('DeleteProject|Failed to remove wiki repository. Please try again or contact administrator.'))
      end

      unless remove_repository(project.design_repository)
        raise_error(s_('DeleteProject|Failed to remove design repository. Please try again or contact administrator.'))
      end
    end

    def trash_relation_repositories!
      unless remove_snippets
        raise_error(s_('DeleteProject|Failed to remove project snippets. Please try again or contact administrator.'))
      end
    end

    def remove_snippets
      # We're setting the skip_authorization param because we dont need to perform the access checks within the service since
      # the user has enough access rights to remove the project and its resources.
      response = ::Snippets::BulkDestroyService.new(current_user, project.snippets).execute(skip_authorization: true)

      if response.error?
        log_error("Snippet deletion failed on #{project.full_path} with the following message: #{response.message}")
      end

      response.success?
    end

    def destroy_events!
      unless remove_events
        raise_error(s_('DeleteProject|Failed to remove events. Please try again or contact administrator.'))
      end
    end

    def remove_events
      log_info("Attempting to destroy events from #{project.full_path} (#{project.id})")

      response = ::Events::DestroyService.new(project).execute

      if response.error?
        log_error("Event deletion failed on #{project.full_path} with the following message: #{response.message}")
      end

      response.success?
    end

    def remove_repository(repository)
      return true unless repository

      result = ::Repositories::DestroyService.new(repository).execute

      result[:status] == :success
    end

    def attempt_rollback(project, message)
      return unless project

      # It's possible that the project was destroyed, but some after_commit
      # hook failed and caused us to end up here. A destroyed model will be a frozen hash,
      # which cannot be altered.
      unless project.destroyed?
        # Restrict project visibility if the parent group visibility was made more restrictive while the project was scheduled for deletion.
        visibility_level = project.visibility_level_allowed_by_group? ? project.visibility_level : project.group.visibility_level
        project.update(delete_error: message, pending_delete: false, visibility_level: visibility_level)
      end

      log_error("Deletion failed on #{project.full_path} with the following message: #{message}")
    end

    def attempt_destroy(project)
      unless remove_registry_tags
        raise_error(s_('DeleteProject|Failed to remove some tags in project container registry. Please try again or contact administrator.'))
      end

      project.leave_pool_repository
      destroy_project_related_records(project)
    end

    def execute_hooks(project)
      system_hook_service.execute_hooks_for(project, :destroy)
    end

    def destroy_project_related_records(project)
      log_destroy_event
      trash_relation_repositories!
      trash_project_repositories!
      destroy_events!
      destroy_web_hooks!
      destroy_project_bots!
      destroy_ci_records!
      destroy_deployments!
      destroy_mr_diff_relations!

      destroy_merge_request_diffs!

      # Rails attempts to load all related records into memory before
      # destroying: https://github.com/rails/rails/issues/22510
      # This ensures we delete records in batches.
      #
      # Exclude container repositories because its before_destroy would be
      # called multiple times, and it doesn't destroy any database records.
      project.destroy_dependent_associations_in_batches(exclude: [:container_repositories, :snippets])
      project.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      raise_error(
        e.record.errors.full_messages.to_sentence
      )
    end

    def log_destroy_event
      log_info("Attempting to destroy #{project.full_path} (#{project.id})")
    end

    # Projects will have at least one merge_request_diff_commit for every commit
    #   contained in every MR, which deleting via `project.destroy!` and
    #   cascading deletes may exceed statement timeouts, causing failures.
    #   (see https://gitlab.com/gitlab-org/gitlab/-/issues/346166)
    #
    # Removing merge_request_diff_files records may also cause timeouts, so they
    #   can be deleted in batches as well.
    #
    # rubocop: disable CodeReuse/ActiveRecord
    def destroy_mr_diff_relations!
      delete_batch_size = 1000

      project.merge_requests.each_batch(column: :iid, of: BATCH_SIZE) do |relation_ids|
        [MergeRequestDiffCommit, MergeRequestDiffFile].each do |model|
          loop do
            inner_query = model
              .select(:merge_request_diff_id, :relative_order)
              .where(merge_request_diff_id: MergeRequestDiff.where(merge_request_id: relation_ids).select(:id))
              .limit(delete_batch_size)

            deleted_rows = model
              .where("(#{model.table_name}.merge_request_diff_id, #{model.table_name}.relative_order) IN (?)", inner_query) # rubocop:disable GitlabSecurity/SqlInjection
              .delete_all

            break if deleted_rows == 0
          end
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def destroy_merge_request_diffs!
      delete_batch_size = 1000

      project.merge_requests.each_batch(column: :iid, of: BATCH_SIZE) do |relation|
        loop do
          deleted_rows = MergeRequestDiff
            .where(merge_request: relation)
            .limit(delete_batch_size)
            .delete_all

          break if deleted_rows == 0
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def destroy_ci_records!
      # Make sure to destroy this first just in case the project is undergoing stats refresh.
      # This is to avoid logging the artifact deletion in Ci::JobArtifacts::DestroyBatchService.
      project.build_artifacts_size_refresh&.destroy

      all_pipelines.find_each(batch_size: BATCH_SIZE) do |pipeline| # rubocop: disable CodeReuse/ActiveRecord
        # Destroy artifacts, then builds, then pipelines
        # All builds have already been dropped by Ci::AbortPipelinesService,
        # so no Ci::Build-instantiating cancellations happen here.
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71342#note_691523196

        # We already have done the permission check for `remove_project` so we can use `unsafe_execute` here.
        # Using `#execute` causes issues with removing pipeline when `ProjectPolicy#repository_disabled` is true.
        ::Ci::DestroyPipelineService.new(project, current_user).unsafe_execute(pipeline)
      end

      project.secure_files.find_each(batch_size: BATCH_SIZE) do |secure_file| # rubocop: disable CodeReuse/ActiveRecord
        ::Ci::DestroySecureFileService.new(project, current_user).execute(secure_file)
      end

      deleted_count = ::CommitStatus.for_project(project).delete_all

      Gitlab::AppLogger.info(
        class: self.class.name,
        project_id: project.id,
        message: 'leftover commit statuses',
        orphaned_commit_status_count: deleted_count
      )
    end

    def destroy_deployments!
      project.deployments.each_batch(of: BATCH_SIZE) do |deployments|
        deployments.fast_destroy_all
      end
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
        result = ::WebHooks::DestroyService.new(current_user).execute(web_hook)

        unless result[:status] == :success
          raise_error(s_('DeleteProject|Failed to remove webhooks. Please try again or contact administrator.'))
        end
      end
    end

    # The project can have multiple project bots with personal access tokens generated.
    # We need to remove them when a project is deleted
    # rubocop: disable CodeReuse/ActiveRecord
    def destroy_project_bots!
      members = project.members
        .allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/422405')
        .includes(:user).references(:user).merge(User.project_bot)

      members.each do |member|
        Users::DestroyService.new(current_user).execute(member.user, skip_authorization: true)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def remove_registry_tags
      return true unless Gitlab.config.registry.enabled
      return false unless remove_legacy_registry_tags

      results = []
      project.container_repositories.find_each do |container_repository|
        results << destroy_repository(project, container_repository)
      end

      results.all?
    end

    ##
    # This method makes sure that we correctly remove registry tags
    # for legacy image repository (when repository path equals project path).
    #
    def remove_legacy_registry_tags
      return true unless Gitlab.config.registry.enabled

      root_repository = ::ContainerRepository.build_root_repository(project)
      root_repository.has_tags? ? destroy_repository(project, root_repository) : true
    end

    def destroy_repository(project, repository)
      service = ContainerRepository::DestroyService.new(project, current_user, { skip_permission_check: true })
      response = service.execute(repository)
      response[:status] == :success
    end

    def raise_error(message)
      raise DestroyError, message
    end

    def flush_caches(project)
      Projects::ForksCountService.new(project).delete_cache
    end

    def publish_project_deleted_event_for(project)
      event = Projects::ProjectDeletedEvent.new(data: {
        project_id: project.id,
        namespace_id: project.namespace_id,
        root_namespace_id: project.root_namespace.id
      })

      Gitlab::EventStore.publish(event)
    end
  end
end

Projects::DestroyService.prepend_mod_with('Projects::DestroyService')
