# frozen_string_literal: true

class UpdateHighestRoleWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :seat_cost_management
  urgency :high
  weight 2

  idempotent!

  def perform(user_id)
    user = User.find_by_id(user_id)

    return unless user.present?

    if user.active? && user.human? && !user.internal?
      Users::UpdateHighestMemberRoleService.new(user).execute
    else
      UserHighestRole.where(user_id: user_id).delete_all # rubocop: disable CodeReuse/ActiveRecord
    end
  end
end
