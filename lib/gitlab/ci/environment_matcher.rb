# frozen_string_literal: true

module Gitlab
  module Ci
    class EnvironmentMatcher
      def initialize(pattern)
        @pattern = pattern
      end

      def match?(environment)
        return false if pattern.blank?

        exact_match?(environment) || wildcard_match?(environment)
      end

      private

      attr_reader :pattern, :match_type

      def exact_match?(environment)
        pattern == environment
      end

      def wildcard_match?(environment)
        return false unless wildcard?

        wildcard_regex.match?(environment)
      end

      def wildcard?
        pattern.include?('*')
      end

      def wildcard_regex
        @wildcard_regex ||= begin
          # Escape everything between the '*'s, then rejoin with '.*?' so only
          # the user's own '*' characters act as wildcards. \A/\z anchor the
          # match to the whole environment name, not a substring of it.
          regex_string = pattern.split('*', -1).map { |segment| Regexp.quote(segment) }.join('.*?')

          Gitlab::UntrustedRegexp.new("\\A#{regex_string}\\z")
        end
      end
    end
  end
end
