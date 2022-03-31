# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    module Processor
      module Concerns
        module ProcessesExceptions
          private

          def extract_exceptions_from(event)
            exceptions = event.instance_variable_get(:@interfaces)[:exception]&.values

            Array.wrap(exceptions)
          end

          def valid_exception?(exception)
            case exception
            when Raven::SingleExceptionInterface
              exception&.value.present?
            else
              false
            end
          end
        end
      end
    end
  end
end
