# frozen_string_literal: true

module Gitlab
  module JiraImport
    class StuckJiraImportJobsWorker # rubocop:disable Scalability/IdempotentWorker
      include Gitlab::Import::StuckImportJob

      private

      def track_metrics(with_jid_count, without_jid_count)
        Gitlab::Metrics.add_event(
          :stuck_jira_import_jobs,
          jira_imports_without_jid_count: with_jid_count,
          jira_imports_with_jid_count: without_jid_count
        )
      end

      def enqueued_import_states
        JiraImportState.with_status([:scheduled, :started])
      end
    end
  end
end
