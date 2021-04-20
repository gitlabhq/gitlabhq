# frozen_string_literal: true

module Packages
  module Debian
    # Parse String as Debian RFC822 control data format
    # https://manpages.debian.org/unstable/dpkg-dev/deb822.5
    class ParseDebian822Service
      InvalidDebian822Error = Class.new(StandardError)

      def initialize(input)
        @input = input
      end

      def execute
        output = {}
        @input.each_line('', chomp: true) do |block|
          section = {}
          section_name, field = nil
          block.each_line(chomp: true) do |line|
            next if comment_line?(line)

            if continuation_line?(line)
              raise InvalidDebian822Error, "Parse error. Unexpected continuation line" if field.nil?

              section[field] += "\n"
              section[field] += line[1..] unless paragraph_separator?(line)
            elsif match = match_section_line(line)
              section_name = match[:name] if section_name.nil?
              field = match[:field]

              raise InvalidDebian822Error, "Duplicate field '#{field}' in section '#{section_name}'" if section.include?(field)

              section[field] = match[:value]
            else
              raise InvalidDebian822Error, "Parse error on line #{line}"
            end
          end

          raise InvalidDebian822Error, "Duplicate section '#{section_name}'" if output[section_name]

          output[section_name] = section
        end

        output
      end

      private

      def comment_line?(line)
        line.match?(/^#/)
      end

      def continuation_line?(line)
        line.match?(/^ /)
      end

      def paragraph_separator?(line)
        line == ' .'
      end

      def match_section_line(line)
        line.match(/(?<name>(?<field>^\S+):\s*(?<value>.*))/)
      end
    end
  end
end
