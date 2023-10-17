# frozen_string_literal: true

module Gitlab
  module Import
    class StuckProjectImportJobsWorker # rubocop:disable Scalability/IdempotentWorker
      include Gitlab::Import::StuckImportJob

      private

      def track_metrics(with_jid_count, without_jid_count)
        Gitlab::Metrics.add_event(
          :stuck_import_jobs,
          projects_without_jid_count: without_jid_count,
          projects_with_jid_count: with_jid_count
        )
      end

      def enqueued_import_states
        ProjectImportState.with_status([:scheduled, :started])
      end
    end
  end
end
