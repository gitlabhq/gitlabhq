# frozen_string_literal: true

module JiraConnect
  class SyncMergeRequestWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    sidekiq_options retry: 3

    queue_namespace :jira_connect
    feature_category :integrations
    data_consistency :delayed

    worker_has_external_dependencies!

    def perform(merge_request_id, update_sequence_id)
      merge_request = MergeRequest.find_by_id(merge_request_id)

      return unless merge_request && merge_request.project

      JiraConnect::SyncService.new(merge_request.project).execute(merge_requests: [merge_request], update_sequence_id: update_sequence_id)
    end
  end
end
