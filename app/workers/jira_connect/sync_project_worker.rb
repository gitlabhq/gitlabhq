# frozen_string_literal: true

module JiraConnect
  class SyncProjectWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include SortingTitlesValuesHelper

    sidekiq_options retry: 3
    queue_namespace :jira_connect
    feature_category :integrations
    data_consistency :delayed
    urgency :low

    worker_has_external_dependencies!

    MAX_RECORDS_LIMIT = 400

    def perform(project_id, update_sequence_id)
      project = Project.find_by_id(project_id)

      return if project.nil?

      sync_params = {
        branches: branches_to_sync(project),
        merge_requests: merge_requests_to_sync(project),
        update_sequence_id: update_sequence_id
      }

      JiraConnect::SyncService.new(project).execute(**sync_params)
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def merge_requests_to_sync(project)
      project.merge_requests.with_jira_issue_keys
        .preload(:author, :approvals, merge_request_reviewers: :reviewer)
        .limit(MAX_RECORDS_LIMIT)
        .order(id: :desc)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def branches_to_sync(project)
      project.repository.branches_sorted_by(SORT_UPDATED_RECENT).filter_map do |branch|
        branch if branch.name.match(Gitlab::Regex.jira_issue_key_regex)
      end.first(MAX_RECORDS_LIMIT)
    end
  end
end
