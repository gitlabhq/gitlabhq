# frozen_string_literal: true

module Users
  class AutoBanService < BaseService
    def initialize(user:, reason:)
      @user = user
      @reason = reason
    end

    def execute
      if user.ban
        record_custom_attribute
        success
      else
        messages = user.errors.full_messages
        error(messages.uniq.join('. '))
      end
    end

    private

    attr_reader :user, :reason

    def record_custom_attribute
      custom_attribute = {
        user_id: user.id,
        key: UserCustomAttribute::AUTO_BANNED_BY,
        value: reason
      }
      UserCustomAttribute.upsert_custom_attributes([custom_attribute])
    end
  end
end
