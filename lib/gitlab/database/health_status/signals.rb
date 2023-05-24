# frozen_string_literal: true

module Gitlab
  module Database
    module HealthStatus
      module Signals
        # Base class for a signal
        class Base
          attr_reader :indicator_class, :reason

          def initialize(indicator_class, reason:)
            @indicator_class = indicator_class
            @reason = reason
          end

          def to_s
            "#{short_name} (indicator: #{indicator_class}; reason: #{reason})"
          end

          def log_info?
            false
          end

          def stop?
            false
          end

          def short_name
            self.class.name.demodulize
          end
        end

        # A Signals::Stop is an indication to put a migration on hold or stop it entirely:
        # In general, we want to slow down or pause the migration.
        class Stop < Base
          def log_info?
            true
          end

          def stop?
            true
          end
        end

        # A Signals::Normal indicates normal system state: We carry on with the migration
        # and may even attempt to optimize its throughput etc.
        class Normal < Base; end

        # When given an Signals::Unknown, something unexpected happened while
        # we evaluated system indicators.
        class Unknown < Base
          def log_info?
            true
          end
        end

        # No signal could be determined, e.g. because the indicator
        # was disabled.
        class NotAvailable < Base; end
      end
    end
  end
end
