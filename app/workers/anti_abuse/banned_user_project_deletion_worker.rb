# frozen_string_literal: true

module AntiAbuse
  class BannedUserProjectDeletionWorker
    include ApplicationWorker
    include CronjobChildWorker

    idempotent!
    feature_category :instance_resiliency
    data_consistency :sticky
    deduplicate :until_executed, including_scheduled: true

    def perform(project_id)
      project = Project.find_by_id(project_id)

      return unless candidate_for_deletion?(project)

      Projects::DestroyService.new(project, Users::Internal.admin_bot).async_execute
    end

    private

    def candidate_for_deletion?(project)
      return false unless project
      return false if project.pending_delete

      project.creator.banned?
    end
  end
end
