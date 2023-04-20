# frozen_string_literal: true

module Users
  class UnblockService < BaseService
    def initialize(current_user)
      @current_user = current_user
    end

    def execute(user)
      if user.activate
        after_unblock_hook(user)
        ServiceResponse.success(payload: { user: user })
      else
        ServiceResponse.error(message: user.errors.full_messages)
      end
    end

    private

    def after_unblock_hook(user)
      custom_attribute = {
        user_id: user.id,
        key: UserCustomAttribute::UNBLOCKED_BY,
        value: "#{current_user.username}/#{current_user.id}+#{Time.current}"
      }
      UserCustomAttribute.upsert_custom_attributes([custom_attribute])
    end
  end
end

Users::UnblockService.prepend_mod_with('Users::UnblockService')
