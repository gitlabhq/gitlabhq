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

      if web_hook.destroy
        after_destroy(web_hook)
      else
        error("Unable to destroy #{web_hook.model_name.human}", 500)
      end
    end

    private

    def after_destroy(web_hook)
      WebHooks::LogDestroyWorker.perform_async({ 'hook_id' => web_hook.id })
      Gitlab::AppLogger.info(log_message(web_hook))

      success({ async: false })
    end

    def log_message(hook)
      "User #{current_user&.id} scheduled a deletion of logs for hook ID #{hook.id}"
    end

    def authorized?(web_hook)
      Ability.allowed?(current_user, :admin_web_hook, web_hook)
    end
  end
end

WebHooks::DestroyService.prepend_mod_with('WebHooks::DestroyService')
