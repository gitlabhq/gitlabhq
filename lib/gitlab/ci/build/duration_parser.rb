# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class DurationParser
        def self.validate_duration(value)
          new(value).validate_duration
        end

        def initialize(value)
          @value = value
        end

        def validate_duration
          return true if never?

          cached_parse
        end

        def seconds_from_now
          parse&.seconds&.from_now
        end

        private

        attr_reader :value

        def cached_parse
          return validation_cache[value] if validation_cache.key?(value)

          validation_cache[value] = safe_parse
        end

        def safe_parse
          parse
        rescue ChronicDuration::DurationParseError
          false
        end

        def parse
          return if never?

          ChronicDuration.parse(value)
        end

        def validation_cache
          Gitlab::SafeRequestStore[:ci_expire_in_parser_cache] ||= {}
        end

        def never?
          value.to_s.casecmp('never') == 0
        end
      end
    end
  end
end
