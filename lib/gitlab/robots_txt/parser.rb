# frozen_string_literal: true

module Gitlab
  module RobotsTxt
    class Parser
      attr_reader :disallow_rules

      def initialize(content)
        @raw_content = content

        @disallow_rules = parse_raw_content!
      end

      def disallowed?(path)
        disallow_rules.any? { |rule| path =~ rule }
      end

      private

      # This parser is very basic as it only knows about `Disallow:` lines,
      # and simply ignores all other lines.
      #
      # Order of predecence, 'Allow:`, etc are ignored for now.
      def parse_raw_content!
        @raw_content.each_line.map do |line|
          if line.start_with?('Disallow:')
            value = line.sub('Disallow:', '').strip
            value = Regexp.escape(value).gsub('\*', '.*')
            Regexp.new("^#{value}")
          else
            nil
          end
        end.compact
      end
    end
  end
end
