# frozen_string_literal: true

module Users
  class BlockService < BaseService
    def initialize(current_user)
      @current_user = current_user
    end

    def execute(user)
      return error('An internal user cannot be blocked', 403) if user.internal?

      if user.block
        after_block_hook(user)
        success
      else
        messages = user.errors.full_messages
        error(messages.uniq.join('. '))
      end
    end

    private

    # overridden by EE module
    def after_block_hook(user)
      custom_attribute = {
        user_id: user.id,
        key: UserCustomAttribute::BLOCKED_BY,
        value: "#{current_user.username}/#{current_user.id}+#{Time.current}"
      }
      UserCustomAttribute.upsert_custom_attributes([custom_attribute])
    end
  end
end

Users::BlockService.prepend_mod_with('Users::BlockService')
