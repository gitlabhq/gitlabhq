# frozen_string_literal: true

module JiraConnect
  class SyncProjectWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    sidekiq_options retry: 3

    queue_namespace :jira_connect
    feature_category :integrations
    data_consistency :delayed, feature_flag: :load_balancing_for_jira_connect_workers
    tags :exclude_from_kubernetes

    worker_has_external_dependencies!

    MERGE_REQUEST_LIMIT = 400

    def perform(project_id, update_sequence_id)
      project = Project.find_by_id(project_id)

      return if project.nil?

      JiraConnect::SyncService.new(project).execute(merge_requests: merge_requests_to_sync(project), update_sequence_id: update_sequence_id)
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def merge_requests_to_sync(project)
      project.merge_requests.with_jira_issue_keys.preload(:author).limit(MERGE_REQUEST_LIMIT).order(id: :desc)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
