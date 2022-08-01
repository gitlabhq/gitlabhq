# frozen_string_literal: true

module WebHooks
  # Destroy a hook, and schedule the logs for deletion.
  class DestroyService
    include Services::ReturnServiceResponses

    attr_accessor :current_user

    DENIED = 'Insufficient permissions'

    def initialize(current_user)
      @current_user = current_user
    end

    def execute(web_hook)
      return error(DENIED, 401) unless authorized?(web_hook)

      hook_id = web_hook.id

      if web_hook.destroy
        WebHooks::LogDestroyWorker.perform_async({ 'hook_id' => hook_id })
        Gitlab::AppLogger.info(log_message(web_hook))

        success({ async: false })
      else
        error("Unable to destroy #{web_hook.model_name.human}", 500)
      end
    end

    private

    def log_message(hook)
      "User #{current_user&.id} scheduled a deletion of logs for hook ID #{hook.id}"
    end

    def authorized?(web_hook)
      Ability.allowed?(current_user, :destroy_web_hook, web_hook)
    end
  end
end
