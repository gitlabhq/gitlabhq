# frozen_string_literal: true

module Projects
  module ImportExport
    class AfterImportMergeRequestsWorker
      include ApplicationWorker

      idempotent!
      data_consistency :delayed
      urgency :low
      feature_category :importers

      def perform(project_id)
        project = Project.find_by_id(project_id)
        return unless project

        project.merge_requests.set_latest_merge_request_diff_ids!
      end
    end
  end
end
