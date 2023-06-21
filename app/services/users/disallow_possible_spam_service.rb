# frozen_string_literal: true

module Users
  class DisallowPossibleSpamService < BaseService
    def initialize(current_user)
      @current_user = current_user
    end

    def execute(user)
      user.custom_attributes.by_key(UserCustomAttribute::ALLOW_POSSIBLE_SPAM).delete_all
    end
  end
end
