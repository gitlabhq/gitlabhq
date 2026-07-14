# frozen_string_literal: true

module Groups
  class DestroyService < Groups::BaseService
    DestroyError = Class.new(StandardError)

    def async_execute
      return UnauthorizedError unless authorize_group_deletion

      mark_deletion_in_progress

      job_id = GroupDestroyWorker.perform_async(group.id, current_user.id)
      Gitlab::AppLogger.info("User #{current_user.id} scheduled a deletion of group ID #{group.id} with job ID #{job_id}")
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def execute
      unless authorize_group_deletion
        group.cancel_deletion!(transition_user: current_user)
        return UnauthorizedError
      end

      ServiceResponse.success(payload: { group: unsafe_execute })
    end

    def unsafe_execute
      mark_deletion_in_progress

      group.projects.includes(:project_feature).find_each do |project|
        # Execute the destruction of the models immediately to ensure atomic cleanup.
        success = ::Projects::DestroyService.new(project, current_user).execute

        raise DestroyError, "Project #{project.id} can't be deleted" unless success
      end

      # reload the relation to prevent triggering destroy hooks on the projects again
      group.projects.reset

      group.children.each do |group|
        # This needs to be synchronous since the namespace gets destroyed below
        DestroyService.new(group, current_user).unsafe_execute
      end

      group.chat_team&.remove_mattermost_team(current_user)

      refresh_authorizations = prepare_authorization_refresh

      destroy_associated_users
      ::Import::BulkImports::RemoveExportUploadsService.new(group).execute

      group.destroy

      refresh_authorizations&.call
      publish_event

      group
    rescue Exception => e # rubocop:disable Lint/RescueException -- Namespace.transaction can raise Exception
      log_payload = {
        group_id: group.id,
        current_user: current_user&.id,
        error_class: e.class,
        error_message: e.message,
        error_backtrace: e.backtrace
      }

      reschedule_deletion
      Gitlab::AppLogger.error(log_payload.merge(message: "Rescheduling group deletion"))

      raise e
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def authorize_group_deletion
      raise DestroyError, "You can't delete this group because you're blocked." if current_user.blocked?

      can?(current_user, :remove_group, group)
    end

    def mark_deletion_in_progress
      Group.transaction do
        group.start_deletion!(transition_user: current_user) unless group.deletion_in_progress?
      end
    end

    def reschedule_deletion
      Group.transaction do
        group.reschedule_deletion!(transition_user: current_user)
      end
    end

    def prepare_authorization_refresh
      project_ids = obtain_project_ids_for_authorization_refresh
      return if project_ids.blank?

      -> do
        Gitlab::AppLogger.info(
          message: "Refreshing project_authorizations for projects previously shared with destroyed group",
          group_id: group.id,
          user_ids_count: 0,
          project_ids_count: project_ids.size
        )

        AuthorizedProjectUpdate::ProjectAccessChangedService.new(project_ids.to_a).execute
      end
    end

    # Destroying a group automatically destroys all project authorizations
    # directly associated with the group and its descendants. However, project
    # authorizations for projects accessible through project and group sharing
    # are not cleaned up automatically. Without a manual refresh, members of
    # the group would retain stale access to:
    # - projects under groups the group was invited to (via group_group_links)
    # - projects directly shared with the group (via project_group_links)
    #
    # We collect affected project IDs before destroying the group (while the share
    # links still exist), then trigger per-project recalculation after the destroy.
    # This is O(K projects) rather than O(N users), matching the pattern used by
    # Groups::TransferService and Projects::GroupLinks::DestroyService.
    #
    # rubocop:disable CodeReuse/ActiveRecord -- Specific use-case
    def obtain_project_ids_for_authorization_refresh
      project_ids = Set.new

      group.shared_group_links.each_batch(of: 50, column: :shared_group_id) do |batch|
        # Use the instance-level `all_projects` (which calls `self_and_descendant_ids` via
        # the fast `traversal_ids @> '{id}'` GIN-indexed operator) rather than the class-level
        # `Namespace.where(...).self_and_descendant_ids` (which uses the expensive
        # `next_traversal_ids_sibling` PL/pgSQL CTE that can time out on large hierarchies).
        Namespace.id_in(batch.pluck(:shared_group_id)).each do |ns|
          project_ids.merge(ns.all_projects.pluck(:id))
        end
      end

      group.project_group_links.each_batch(of: 50, column: :project_id) do |batch|
        project_ids.merge(batch.pluck(:project_id))
      end

      project_ids
    end
    # rubocop:enable CodeReuse/ActiveRecord

    def destroy_associated_users
      current_user_id = current_user.id
      bot_ids = users_to_destroy

      group.run_after_commit do
        bot_ids.each do |user_id|
          DeleteUserWorker.perform_async(current_user_id, user_id, 'skip_authorization' => true)
        end
      end
    end

    # rubocop:disable CodeReuse/ActiveRecord
    def users_to_destroy
      group.members_and_requesters.joins(:user)
        .merge(User.project_bot)
        .allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/422405')
        .pluck(:user_id)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    def publish_event
      event_data = {
        group_id: group.id,
        root_namespace_id: group.root_ancestor&.id.to_i # remove safe navigation and `.to_i` with https://gitlab.com/gitlab-org/gitlab/-/issues/508611
      }
      event_data[:parent_namespace_id] = group.parent_id if group.parent_id.present?

      Gitlab::EventStore.publish(Groups::GroupDeletedEvent.new(data: event_data))
    end
  end
end

Groups::DestroyService.prepend_mod_with('Groups::DestroyService')
