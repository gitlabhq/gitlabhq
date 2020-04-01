# frozen_string_literal: true

class UpdateHighestRoleWorker
  include ApplicationWorker

  feature_category :authentication_and_authorization
  urgency :high
  weight 2

  idempotent!

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(user_id)
    user = User.find_by(id: user_id)

    return unless user.present?

    if user.active? && user.user_type.nil? && !user.internal?
      Users::UpdateHighestMemberRoleService.new(user).execute
    else
      UserHighestRole.where(user_id: user_id).delete_all
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
