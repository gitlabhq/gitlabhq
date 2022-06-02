# frozen_string_literal: true

module WebHooks
  class LogDestroyService
    BATCH_SIZE = 1000

    def initialize(web_hook_id)
      @web_hook_id = web_hook_id
    end

    def execute
      next while WebHookLog.delete_batch_for(@web_hook_id, batch_size: BATCH_SIZE)

      ServiceResponse.success
    rescue StandardError => ex
      ServiceResponse.error(message: ex.message)
    end
  end
end
