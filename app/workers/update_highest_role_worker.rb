# frozen_string_literal: true

class UpdateHighestRoleWorker
  include ApplicationWorker

  feature_category :authentication_and_authorization
  urgency :high
  weight 2

  idempotent!

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(user_id)
    user = User.active.find_by(id: user_id)

    Users::UpdateHighestMemberRoleService.new(user).execute if user.present?
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
