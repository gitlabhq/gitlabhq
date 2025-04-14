# frozen_string_literal: true

module ActiveContext
  class ErrorHandler
    def self.log_and_raise_error(exception, **kwargs)
      ::ActiveContext::Logger.exception(exception, **kwargs)
      raise exception
    end
  end
end
