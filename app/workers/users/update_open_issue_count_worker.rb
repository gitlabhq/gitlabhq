# frozen_string_literal: true

module Users
  class UpdateOpenIssueCountWorker
    include ApplicationWorker

    feature_category :users
    tags :exclude_from_kubernetes
    idempotent!

    def perform(target_user_ids)
      target_user_ids = Array.wrap(target_user_ids)

      raise ArgumentError, 'No target user ID provided' if target_user_ids.empty?

      target_users = User.id_in(target_user_ids)
      raise ArgumentError, 'No valid target user ID provided' if target_users.empty?

      target_users.each do |user|
        Users::UpdateAssignedOpenIssueCountService.new(target_user: user).execute
      end
    rescue StandardError => exception
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(exception)
    end
  end
end
