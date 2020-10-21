# frozen_string_literal: true

module WebHooks
  class DestroyService
    include BaseServiceUtility

    BATCH_SIZE = 1000
    LOG_COUNT_THRESHOLD = 10000

    DestroyError = Class.new(StandardError)

    attr_accessor :current_user, :web_hook

    def initialize(current_user)
      @current_user = current_user
    end

    def execute(web_hook)
      @web_hook = web_hook

      async = false
      # For a better user experience, it's better if the Web hook is
      # destroyed right away without waiting for Sidekiq. However, if
      # there are a lot of Web hook logs, we will need more time to
      # clean them up, so schedule a Sidekiq job to do this.
      if needs_async_destroy?
        Gitlab::AppLogger.info("User #{current_user&.id} scheduled a deletion of hook ID #{web_hook.id}")
        async_destroy(web_hook)
        async = true
      else
        sync_destroy(web_hook)
      end

      success({ async: async })
    end

    def sync_destroy(web_hook)
      @web_hook = web_hook

      delete_web_hook_logs
      result = web_hook.destroy

      if result
        success({ async: false })
      else
        error("Unable to destroy #{web_hook.model_name.human}")
      end
    end

    private

    def async_destroy(web_hook)
      WebHooks::DestroyWorker.perform_async(current_user.id, web_hook.id)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def needs_async_destroy?
      web_hook.web_hook_logs.limit(LOG_COUNT_THRESHOLD).count == LOG_COUNT_THRESHOLD
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def delete_web_hook_logs
      loop do
        count = delete_web_hook_logs_in_batches
        break if count < BATCH_SIZE
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def delete_web_hook_logs_in_batches
      # We can't use EachBatch because that does an ORDER BY id, which can
      # easily time out. We don't actually care about ordering when
      # we are deleting these rows.
      web_hook.web_hook_logs.limit(BATCH_SIZE).delete_all
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
