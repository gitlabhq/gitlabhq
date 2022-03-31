# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    module Processor
      module SanitizeErrorMessageProcessor
        extend Gitlab::ErrorTracking::Processor::Concerns::ProcessesExceptions

        class << self
          def call(event)
            exceptions = extract_exceptions_from(event)

            exceptions.each do |exception|
              next unless valid_exception?(exception)

              message = Gitlab::Sanitizers::ExceptionMessage.clean(exception.type, exception.value)

              set_exception_message(exception, message)
            end

            event
          end
        end
      end
    end
  end
end
