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
      update_hook_failure_state
      log_execution
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
      in_lock(lock_name, ttl: LOCK_TTL, sleep_sec: LOCK_SLEEP, retries: LOCK_RETRY) do |_retried|
        hook.reset # Reload within the lock so properties are guaranteed to be current.

        case response_category
        when :ok
          hook.enable!
        when :error
          hook.backoff!
        when :failed
          hook.failed!
        end

        hook.parent.update_last_webhook_failure(hook) if hook.parent
      end
    rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
      raise if raise_lock_error?
    end

    def lock_name
      "web_hooks:update_hook_failure_state:#{hook.id}"
    end

    # Allow an error to be raised after failing to obtain a lease only if the hook
    # is not already in the correct failure state.
    def raise_lock_error?
      hook.reset # Reload so properties are guaranteed to be current.

      hook.executable? != (response_category == :ok)
    end
  end
end
