# frozen_string_literal: true

module Groups
  class DestroyService < Groups::BaseService
    DestroyError = Class.new(StandardError)

    def async_execute
      mark_deleted

      job_id = GroupDestroyWorker.perform_async(group.id, current_user.id)
      Gitlab::AppLogger.info("User #{current_user.id} scheduled a deletion of group ID #{group.id} with job ID #{job_id}")
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def execute
      # TODO - add a policy check here https://gitlab.com/gitlab-org/gitlab/-/issues/353082
      raise DestroyError, "You can't delete this group because you're blocked." if current_user.blocked?

      mark_deleted

      group.projects.includes(:project_feature).find_each do |project|
        # Execute the destruction of the models immediately to ensure atomic cleanup.
        success = ::Projects::DestroyService.new(project, current_user).execute

        raise DestroyError, "Project #{project.id} can't be deleted" unless success
      end

      # reload the relation to prevent triggering destroy hooks on the projects again
      group.projects.reset

      group.children.each do |group|
        # This needs to be synchronous since the namespace gets destroyed below
        DestroyService.new(group, current_user).execute
      end

      group.chat_team&.remove_mattermost_team(current_user)

      user_ids_for_project_authorizations_refresh = obtain_user_ids_for_project_authorizations_refresh

      destroy_associated_users

      group.destroy

      if user_ids_for_project_authorizations_refresh.present?
        UserProjectAccessChangedService
          .new(user_ids_for_project_authorizations_refresh)
          .execute
      end

      publish_event

      group
    rescue Exception # rubocop:disable Lint/RescueException -- Namespace.transaction can raise Exception
      unmark_deleted
      raise
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def mark_deleted
      group.update_attribute(:deleted_at, Time.current)
    end

    def unmark_deleted
      group.update_attribute(:deleted_at, nil)
    end

    def any_groups_shared_with_this_group?
      group.shared_group_links.any?
    end

    def any_projects_shared_with_this_group?
      group.project_group_links.any?
    end

    # Destroying a group automatically destroys all project authorizations directly
    # associated with the group and descendents. However, project authorizations
    # for projects and groups this group is shared with are not. Without a manual
    # refresh, the project authorization records of these users to shared projects
    # and projects within the shared groups will never be removed, causing
    # inconsistencies with access permissions.
    #
    # This method retrieves the user IDs that need to be refreshed. If only
    # groups are shared with this group, only direct members need to be refreshed.
    # If projects are also shared with the group, direct members *and* shared
    # members of other groups need to be refreshed.
    # `Group#user_ids_for_project_authorizations` returns both direct and shared
    # members' user IDs.
    def obtain_user_ids_for_project_authorizations_refresh
      return unless any_projects_shared_with_this_group? || any_groups_shared_with_this_group?
      return group.user_ids_for_project_authorizations if any_projects_shared_with_this_group?

      group.users_ids_of_direct_members
    end

    def destroy_associated_users
      current_user_id = current_user.id
      bot_ids = users_to_destroy

      group.run_after_commit do
        bot_ids.each do |user_id|
          DeleteUserWorker.perform_async(current_user_id, user_id, skip_authorization: true)
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
      event = Groups::GroupDeletedEvent.new(
        data: {
          group_id: group.id,
          root_namespace_id: group.root_ancestor&.id.to_i # remove safe navigation and `.to_i` with https://gitlab.com/gitlab-org/gitlab/-/issues/508611
        }
      )

      Gitlab::EventStore.publish(event)
    end
  end
end

Groups::DestroyService.prepend_mod_with('Groups::DestroyService')
