# frozen_string_literal: true

module WebHooks
  class LogExecutionService
    include ::Gitlab::ExclusiveLeaseHelpers

    LOCK_TTL = 15.seconds.freeze
    LOCK_SLEEP = 0.25.seconds.freeze
    LOCK_RETRY = 65

    attr_reader :hook, :log_data, :response_category

    def initialize(hook:, log_data:, response_category:)
      @hook = hook
      @log_data = log_data.as_json
      @response_category = response_category
    end

    def execute
      log_execution
      update_hook_failure_state
    end

    private

    def log_execution
      mask_response_headers

      log_data['request_headers']['X-Gitlab-Token'] = _('[REDACTED]') if hook.token?

      WebHookLog.create!(web_hook: hook, **log_data)
    end

    def mask_response_headers
      return unless hook.url_variables?
      return unless log_data.key?('response_headers')

      variables_map = hook.url_variables.invert.transform_values { "{#{_1}}" }
      regex = Regexp.union(variables_map.keys)

      log_data['response_headers'].transform_values! do |value|
        regex === value ? value.gsub(regex, variables_map) : value
      end
    end

    # Perform this operation within an `Gitlab::ExclusiveLease` lock to make it
    # safe to be called concurrently from different workers.
    def update_hook_failure_state
      return unless hook.auto_disabling_enabled?

      in_lock(lock_name, ttl: LOCK_TTL, sleep_sec: LOCK_SLEEP, retries: LOCK_RETRY) do |_retried|
        hook.reset # Reload within the lock so properties are guaranteed to be current.

        case response_category
        when :ok
          hook.enable!
        # TODO remove handling of `:failed` as part of
        # https://gitlab.com/gitlab-org/gitlab/-/issues/525446
        when :error, :failed
          hook.backoff!
        end

        hook.parent.update_last_webhook_failure(hook) if hook.parent
      end
    rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
      # In case the lock is not obtained due to numerous concurrent requests,
      # we do not attempt to update the hook status.
      #
      # This should be fine as if the lock is not obtained, it is likely due
      # to many concurrent job executions, and eventually one of these should
      # successfully obtain the lease and update the hook status.
    rescue StandardError => e
      # To avoid WebHookLog being created twice in case an exception is raised
      # when updating the hook status and the job retried.
      Gitlab::ErrorTracking.track_exception(e, hook_id: hook.id)
    end

    def lock_name
      "web_hooks:update_hook_failure_state:#{hook.id}"
    end
  end
end
