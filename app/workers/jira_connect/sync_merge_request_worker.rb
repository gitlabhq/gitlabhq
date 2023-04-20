# frozen_string_literal: true

module JiraConnect
  class SyncMergeRequestWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    queue_namespace :jira_connect
    feature_category :integrations
    data_consistency :delayed
    urgency :low

    worker_has_external_dependencies!

    def perform(merge_request_id, update_sequence_id)
      merge_request = MergeRequest.find_by_id(merge_request_id)
      project = merge_request&.project

      return unless merge_request && project

      branches = [project.repository.find_branch(merge_request.source_branch)].compact.presence if merge_request.open?

      JiraConnect::SyncService.new(project).execute(merge_requests: [merge_request], branches: branches, update_sequence_id: update_sequence_id)
    end
  end
end
