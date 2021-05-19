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

    def after_block_hook(user)
      # overridden by EE module
    end
  end
end

Users::BlockService.prepend_mod_with('Users::BlockService')
