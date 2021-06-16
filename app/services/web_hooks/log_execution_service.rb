# frozen_string_literal: true

module WebHooks
  class LogExecutionService
    attr_reader :hook, :log_data, :response_category

    def initialize(hook:, log_data:, response_category:)
      @hook = hook
      @log_data = log_data
      @response_category = response_category
    end

    def execute
      update_hook_executability
      log_execution
    end

    private

    def log_execution
      WebHookLog.create!(web_hook: hook, **log_data.transform_keys(&:to_sym))
    end

    def update_hook_executability
      case response_category
      when :ok
        hook.enable!
      when :error
        hook.backoff!
      when :failed
        hook.failed!
      end
    end
  end
end
