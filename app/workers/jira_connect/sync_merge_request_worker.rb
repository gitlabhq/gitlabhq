# frozen_string_literal: true

module JiraConnect
  class SyncMergeRequestWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    queue_namespace :jira_connect
    feature_category :integrations

    def perform(merge_request_id, update_sequence_id = nil)
      merge_request = MergeRequest.find_by_id(merge_request_id)

      return unless merge_request && merge_request.project

      JiraConnect::SyncService.new(merge_request.project).execute(merge_requests: [merge_request], update_sequence_id: update_sequence_id)
    end
  end
end
