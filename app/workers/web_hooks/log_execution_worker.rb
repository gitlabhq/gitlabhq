# frozen_string_literal: true

module WebHooks
  class LogExecutionWorker
    include ApplicationWorker

    data_consistency :always

    idempotent!
    feature_category :integrations
    urgency :low

    # This worker accepts an extra argument. This enables us to
    # treat this worker as idempotent. Currently this is set to
    # the Job ID (jid) of the parent worker.
    def perform(hook_id, log_data, response_category, _unique_by)
      hook = WebHook.find_by_id(hook_id)

      return unless hook # hook has been deleted before we could run.

      ::WebHooks::LogExecutionService
        .new(hook: hook, log_data: log_data, response_category: response_category.to_sym)
        .execute
    end
  end
end
