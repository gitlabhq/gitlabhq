# frozen_string_literal: true

module Namespaces
  class InviteTeamEmailWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    feature_category :experimentation_activation
    urgency :low

    def perform(group_id, user_id)
      # rubocop: disable CodeReuse/ActiveRecord
      user = User.find_by(id: user_id)
      group = Group.find_by(id: group_id)
      # rubocop: enable CodeReuse/ActiveRecord
      return unless user && group

      Namespaces::InviteTeamEmailService.send_email(user, group)
    end
  end
end
