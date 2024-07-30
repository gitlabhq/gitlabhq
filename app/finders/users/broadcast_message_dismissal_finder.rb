# frozen_string_literal: true

module Users
  class BroadcastMessageDismissalFinder
    def initialize(user, message_ids:)
      @user = user
      @message_ids = message_ids
    end

    def execute
      Users::BroadcastMessageDismissal.valid_dismissals.for_user_and_broadcast_message(user, message_ids)
    end

    private

    attr_reader :user, :message_ids
  end
end
