# frozen_string_literal: true

module Users
  class AllowPossibleSpamService < BaseService
    def initialize(current_user)
      @current_user = current_user
    end

    def execute(user)
      custom_attribute = {
        user_id: user.id,
        key: UserCustomAttribute::ALLOW_POSSIBLE_SPAM,
        value: "#{current_user.username}/#{current_user.id}+#{Time.current}"
      }
      UserCustomAttribute.upsert_custom_attributes([custom_attribute])
    end
  end
end
