# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Artifacts
        class ExpireInParser
          def self.validate_duration(value)
            new(value).validate_duration
          end

          def initialize(value)
            @value = value
          end

          def validate_duration
            return true if never?

            parse
          rescue ChronicDuration::DurationParseError
            false
          end

          def seconds_from_now
            parse&.seconds&.from_now
          end

          private

          attr_reader :value

          def parse
            return if never?

            ChronicDuration.parse(value)
          end

          def never?
            value.to_s.casecmp('never') == 0
          end
        end
      end
    end
  end
end
