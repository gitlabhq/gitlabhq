# frozen_string_literal: true

module Gitlab
  module Chat
    # Class for gathering and formatting the output of a `Ci::Build`.
    class Output
      attr_reader :build

      MissingBuildSectionError = Class.new(StandardError)

      # The primary trace section to look for.
      PRIMARY_SECTION = 'chat_reply'

      # The backup trace section in case the primary one could not be found.
      FALLBACK_SECTION = 'build_script'

      # build - The `Ci::Build` to obtain the output from.
      def initialize(build)
        @build = build
      end

      # Returns a `String` containing the output of the build.
      #
      # The output _does not_ include the command that was executed.
      def to_s
        offset, length = read_offset_and_length

        trace.read do |stream|
          stream.seek(offset)

          output = stream
            .stream
            .read(length)
            .force_encoding(Encoding.default_external)

          without_executed_command_line(output)
        end
      end

      # Returns the offset to seek to and the number of bytes to read relative
      # to the offset.
      def read_offset_and_length
        section = find_build_trace_section(PRIMARY_SECTION) ||
          find_build_trace_section(FALLBACK_SECTION)

        unless section
          raise(
            MissingBuildSectionError,
            "The build_script trace section could not be found for build #{build.id}"
          )
        end

        length = section[:byte_end] - section[:byte_start]

        [section[:byte_start], length]
      end

      # Removes the line containing the executed command from the build output.
      #
      # output - A `String` containing the output of a trace section.
      def without_executed_command_line(output)
        # If `output.split("\n")` produces an empty Array then the slicing that
        # follows it will produce a nil. For example:
        #
        #     "\n".split("\n")        # => []
        #     "\n".split("\n")[1..-1] # => nil
        #
        # To work around this we only "join" if we're given an Array.
        if (converted = output.split("\n")[1..-1])
          converted.join("\n")
        else
          ''
        end
      end

      # Returns the trace section for the given name, or `nil` if the section
      # could not be found.
      #
      # name - The name of the trace section to find.
      def find_build_trace_section(name)
        trace_sections.find { |s| s[:name] == name }
      end

      def trace_sections
        @trace_sections ||= trace.extract_sections
      end

      def trace
        @trace ||= build.trace
      end
    end
  end
end
