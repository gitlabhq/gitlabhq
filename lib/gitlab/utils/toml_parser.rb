# frozen_string_literal: true

module Gitlab
  module Utils
    class TomlParser
      PARSE_TIMEOUT = 2.seconds

      ParseError = Class.new(StandardError)

      def self.safe_parse(content)
        Timeout.timeout(PARSE_TIMEOUT) do
          TomlRB.parse(content)
        end
      rescue TomlRB::ParseError
        raise ParseError, 'content is not valid TOML'
      rescue Timeout::Error => e
        Gitlab::ErrorTracking.log_exception(e)
        raise ParseError, 'timeout while parsing TOML'
      rescue TomlRB::Error => e
        raise ParseError, "error parsing TOML: #{e.message}"
      end
    end
  end
end
