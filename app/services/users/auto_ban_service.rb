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
        ban_duplicate_users
        success
      else
        messages = user.errors.full_messages
        error(messages.uniq.join('. '))
      end
    end

    def execute!
      user.ban!
      record_custom_attribute
      ban_duplicate_users
      success
    end

    private

    attr_reader :user, :reason

    def ban_duplicate_users
      AntiAbuse::BanDuplicateUsersWorker.perform_async(user.id)
    end

    def record_custom_attribute
      UserCustomAttribute.set_auto_banned_by(user: user, reason: reason)
    end
  end
end

Users::AutoBanService.prepend_mod
