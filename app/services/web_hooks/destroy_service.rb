# frozen_string_literal: true

module WebHooks
  class DestroyService
    attr_accessor :current_user

    def initialize(current_user)
      @current_user = current_user
    end

    # Destroy the hook immediately, schedule the logs for deletion
    def execute(web_hook)
      hook_id = web_hook.id

      if web_hook.destroy
        WebHooks::LogDestroyWorker.perform_async({ 'hook_id' => hook_id })
        Gitlab::AppLogger.info("User #{current_user&.id} scheduled a deletion of logs for hook ID #{hook_id}")

        ServiceResponse.success(payload: { async: false })
      else
        ServiceResponse.error(message: "Unable to destroy #{web_hook.model_name.human}")
      end
    end
  end
end
