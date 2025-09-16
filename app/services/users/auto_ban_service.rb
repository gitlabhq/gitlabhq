# frozen_string_literal: true

module Users
  class AutoBanService
    Error = Class.new(StandardError)

    def initialize(user:, reason:)
      @user = user
      @reason = reason
    end

    def execute
      ban_user
    end

    def execute!
      result = ban_user

      raise Error, result[:message] if result[:status] == :error
    end

    private

    attr_reader :user, :reason

    def ban_user
      result = ::Users::BanService.new(admin_bot).execute(user)

      record_custom_attribute if result[:status] == :success

      result
    end

    def admin_bot
      Users::Internal.for_organization(user.organization_id).admin_bot
    end

    def ban_duplicate_users
      AntiAbuse::BanDuplicateUsersWorker.perform_async(user.id)
    end

    def record_custom_attribute
      UserCustomAttribute.set_auto_banned_by(user: user, reason: reason)
    end
  end
end

Users::AutoBanService.prepend_mod
