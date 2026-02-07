# frozen_string_literal: true

# rubocop:disable Scalability/IdempotentWorker -- Sends an email
module MergeRequests
  module Refresh
    class NotifyAboutPushWorker
      include ApplicationWorker

      deduplicate :until_executed
      feature_category :code_review_workflow
      urgency :low
      data_consistency :sticky
      defer_on_database_health_signal :gitlab_main

      def perform(
        merge_request_id, user_id, new_commits_data, total_new_commits_count, existing_commits_data,
        total_existing_commits_count)
        merge_request = MergeRequest.find_by_id(merge_request_id)
        return unless merge_request

        user = User.find_by_id(user_id)
        return unless user

        new_commits = new_commits_data.map(&:symbolize_keys)
        existing_commits = existing_commits_data.map(&:symbolize_keys)

        NotificationService.new.push_to_merge_request_with_data(
          merge_request,
          user,
          new_commits_data: new_commits,
          total_new_commits_count: total_new_commits_count,
          existing_commits_data: existing_commits,
          total_existing_commits_count: total_existing_commits_count
        )
      end
    end
  end
end
# rubocop:enable Scalability/IdempotentWorker
