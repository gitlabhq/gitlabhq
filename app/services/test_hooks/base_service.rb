module TestHooks
  class BaseService
    attr_accessor :hook, :current_user, :trigger

    def initialize(hook, current_user, trigger)
      @hook = hook
      @current_user = current_user
      @trigger = trigger
    end

    def execute
      trigger_data_method = "#{trigger}_data"

      if !self.respond_to?(trigger_data_method, true) ||
          !hook.class::TRIGGERS.value?(trigger.to_sym)

        return error('Testing not available for this hook')
      end

      error_message = catch(:validation_error) do
        sample_data = self.__send__(trigger_data_method)

        return hook.execute(sample_data, trigger)
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
