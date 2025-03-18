# frozen_string_literal: true

module Gitlab
  module Import
    class ImportFileCleanupWorker
      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- no context in this worker

      idempotent!
      feature_category :importers
      data_consistency :sticky

      def perform
        ::Import::ImportFileCleanupService.new.execute
      end
    end
  end
end
