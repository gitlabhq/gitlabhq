# frozen_string_literal: true

module Gitlab
  module RobotsTxt
    class Parser
      DISALLOW_REGEX = /^disallow: /i
      ALLOW_REGEX = /^allow: /i

      attr_reader :disallow_rules, :allow_rules

      def initialize(content)
        @raw_content = content

        @disallow_rules, @allow_rules = parse_raw_content!
      end

      def disallowed?(path)
        return false if allow_rules.any? { |rule| path =~ rule }

        disallow_rules.any? { |rule| path =~ rule }
      end

      private

      # This parser is very basic as it only knows about `Disallow:`
      # and `Allow:` lines, and simply ignores all other lines.
      #
      # Patterns ending in `$`, and `*` for 0 or more characters are recognized.
      #
      # It is case insensitive and `Allow` rules takes precedence
      # over `Disallow`.
      def parse_raw_content!
        disallowed = []
        allowed = []

        @raw_content.each_line.each do |line|
          if disallow_rule?(line)
            disallowed << get_disallow_pattern(line)
          elsif allow_rule?(line)
            allowed << get_allow_pattern(line)
          end
        end

        [disallowed, allowed]
      end

      def disallow_rule?(line)
        line =~ DISALLOW_REGEX
      end

      def get_disallow_pattern(line)
        get_pattern(line, DISALLOW_REGEX)
      end

      def allow_rule?(line)
        line =~ ALLOW_REGEX
      end

      def get_allow_pattern(line)
        get_pattern(line, ALLOW_REGEX)
      end

      def get_pattern(line, rule_regex)
        value = line.sub(rule_regex, '').strip
        value = Regexp.escape(value).gsub('\*', '.*')
        value = value.sub(/\\\$$/, '$')
        Regexp.new("^#{value}")
      end
    end
  end
end
