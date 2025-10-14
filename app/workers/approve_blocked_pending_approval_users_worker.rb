# frozen_string_literal: true

class ApproveBlockedPendingApprovalUsersWorker
  include ApplicationWorker

  data_consistency :sticky

  sidekiq_options retry: 3

  idempotent!

  feature_category :user_profile

  def perform(current_user_id)
    current_user = User.find_by_id(current_user_id)

    if current_user.blank?
      Sidekiq.logger.warn(
        class: self.class.name,
        user_id: current_user_id,
        message: "user not found"
      )
      return
    end

    User.blocked_pending_approval.find_each do |user|
      Users::ApproveService.new(current_user).execute(user)
    end
  end
end
