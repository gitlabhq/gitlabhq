# frozen_string_literal: true

module Users
  class BroadcastMessageDismissalFinder
    def initialize(user)
      @user = user
    end

    def execute
      Users::BroadcastMessageDismissal.valid_dismissals.for_user(user)
    end

    private

    attr_reader :user, :message_ids
  end
end
