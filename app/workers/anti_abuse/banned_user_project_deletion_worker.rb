# frozen_string_literal: true

module AntiAbuse
  class BannedUserProjectDeletionWorker
    include ApplicationWorker
    include CronjobChildWorker

    idempotent!
    feature_category :instance_resiliency
    data_consistency :sticky
    deduplicate :until_executed, including_scheduled: true

    ACTIVITY_THRESHOLD = 30

    ProjectNotEligibleForDeletion = Class.new(StandardError)

    def perform(project_id)
      return if Feature.disabled?(:delete_banned_user_projects, :instance, type: :gitlab_com_derisk)

      @project = Project.find_by_id(project_id)

      return unless project
      return if project.pending_delete

      verify_project!

      Projects::DestroyService.new(project, Users::Internal.admin_bot).async_execute

    rescue ProjectNotEligibleForDeletion => e
      log_error(e.message)
    end

    private

    attr_reader :project

    def verify_project!
      ensure_inactive_project!
      ensure_creator_owner_is_banned!
      ensure_no_active_owners!
    end

    def ensure_inactive_project!
      return if project.last_activity_at < ACTIVITY_THRESHOLD.days.ago

      abort!('active project')
    end

    def ensure_creator_owner_is_banned!
      return if Project.id_in(project.id).with_created_and_owned_by_banned_user.exists?

      abort!('user status change')
    end

    def ensure_no_active_owners!
      return unless Project.id_in(project.id).with_active_owners.exists?

      abort!('project is co-owned by other active users')
    end

    def log_error(reason)
      Gitlab::AppLogger.info(
        class: self.class.name,
        message: 'aborted banned user project auto-deletion',
        reason: reason,
        project_id: project.id,
        full_path: project.full_path,
        banned_user_id: project.creator_id
      )
    end

    def abort!(reason)
      raise ProjectNotEligibleForDeletion, reason
    end
  end
end

::AntiAbuse::BannedUserProjectDeletionWorker.prepend_mod
