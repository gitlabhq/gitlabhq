# frozen_string_literal: true

module Gitlab
  module Export
    class PruneProjectExportJobsWorker
      include ApplicationWorker

      # rubocop:disable Scalability/CronWorkerContext
      # This worker updates several import states inline and does not schedule
      # other jobs. So no context needed
      include CronjobQueue
      # rubocop:enable Scalability/CronWorkerContext

      feature_category :importers
      data_consistency :sticky
      idempotent!

      def perform
        Projects::ImportExport::PruneExpiredExportJobsService.execute
      end
    end
  end
end
