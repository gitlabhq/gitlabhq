module TestHooks
  class BaseService
    attr_accessor :hook, :current_user, :trigger

    def initialize(hook, current_user, trigger)
      @hook = hook
      @current_user = current_user
      @trigger = trigger
    end

    def execute
      trigger_key = hook.class.triggers.key(trigger.to_sym)
      trigger_data_method = "#{trigger}_data"

      if trigger_key.nil? || !self.respond_to?(trigger_data_method, true)
        return error('Testing not available for this hook')
      end

      error_message = catch(:validation_error) do
        sample_data = self.__send__(trigger_data_method) # rubocop:disable GitlabSecurity/PublicSend

        return hook.execute(sample_data, trigger_key)
      end

      error(error_message)
    end

    private

    def error(message, http_status = nil)
      result = {
        message: message,
        status: :error
      }

      result[:http_status] = http_status if http_status
      result
    end
  end
end
