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
        @wildcard_regex ||= Regexp.new(pattern.gsub('*', '.*'))
      end
    end
  end
end
