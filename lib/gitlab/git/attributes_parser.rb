# frozen_string_literal: true

module Gitlab
  module Git
    # Class for parsing Git attribute files and extracting the attributes for
    # file patterns.
    class AttributesParser
      def initialize(attributes_data = "")
        @data = attributes_data || ""
      end

      # Returns all the Git attributes for the given path.
      #
      # file_path - A path to a file for which to get the attributes.
      #
      # Returns a Hash.
      def attributes(file_path)
        absolute_path = File.join('/', file_path)

        patterns.each do |pattern, attrs|
          return attrs if File.fnmatch?(pattern, absolute_path)
        end

        {}
      end

      # Returns a Hash containing the file patterns and their attributes.
      def patterns
        @patterns ||= parse_data
      end

      # Parses an attribute string.
      #
      # These strings can be in the following formats:
      #
      #     text      # => { "text" => true }
      #     -text     # => { "text" => false }
      #     key=value # => { "key" => "value" }
      #
      # string - The string to parse.
      #
      # Returns a Hash containing the attributes and their values.
      def parse_attributes(string)
        values = {}
        dash = '-'
        equal = '='
        binary = 'binary'

        string.split(/\s+/).each do |chunk|
          # Data such as "foo = bar" should be treated as "foo" and "bar" being
          # separate boolean attributes.
          next if chunk == equal

          key = chunk

          # Input: "-foo"
          if chunk.start_with?(dash)
            key = chunk.byteslice(1, chunk.length - 1)
            value = false

          # Input: "foo=bar"
          elsif chunk.include?(equal)
            key, value = chunk.split(equal, 2)

          # Input: "foo"
          else
            value = true
          end

          values[key] = value

          # When the "binary" option is set the "diff" option should be set to
          # the inverse. If "diff" is later set it should overwrite the
          # automatically set value.
          values['diff'] = false if key == binary && value
        end

        values
      end

      # Iterates over every line in the attributes file.
      def each_line
        @data.each_line do |line|
          break unless line.valid_encoding?

          yield line.strip
        end
      # Catch invalid byte sequences
      rescue ArgumentError
      end

      private

      # Parses the Git attributes file contents.
      def parse_data
        pairs = []
        comment = '#'

        each_line do |line|
          next if line.start_with?(comment) || line.empty?

          pattern, attrs = line.split(/\s+/, 2)

          parsed = attrs ? parse_attributes(attrs) : {}

          absolute_pattern = File.join('/', pattern)
          pairs << [absolute_pattern, parsed]
        end

        # Newer entries take precedence over older entries.
        pairs.reverse.to_h
      end
    end
  end
end
