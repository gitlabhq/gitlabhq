# frozen_string_literal: true

class ApproveBlockedPendingApprovalUsersWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  idempotent!

  feature_category :users
  tags :exclude_from_kubernetes

  def perform(current_user_id)
    current_user = User.find(current_user_id)

    User.blocked_pending_approval.find_each do |user|
      Users::ApproveService.new(current_user).execute(user)
    end
  end
end
