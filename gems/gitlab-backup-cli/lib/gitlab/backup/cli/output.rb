# frozen_string_literal: true

require 'rainbow/refinement'

module Gitlab
  module Backup
    module Cli
      module Output
        # Add Rainbow color refinement support
        using Rainbow

        ICONS = {
          info: "\u2139\ufe0f ", # requires an extra space
          success: "\u2705\ufe0f",
          warning: "\u26A0\ufe0f ", # requires an extra space
          error: "\u274C\ufe0f",
          debug: "\u26CF\ufe0f " # requires an extra space
        }.freeze

        STATES = [
          :success,
          :failure,
          :skipped
        ].freeze

        class << self
          # Display info content on a new line with default formatting (stdout)
          #
          # @param [String] content
          def info(content)
            self.puts("#{ICONS[:info]} #{content}")
          end

          def success(content)
            self.puts("#{ICONS[:success]} #{content}")
          end

          def print_info(content)
            self.print("#{ICONS[:info]} #{content}", timestamp: true)
          end

          # Prints a success/failure tag with default formatting and colors
          #
          # @param [Symbol] status is one of the symbols defined in STATES
          def print_tag(status)
            output =
              case status
              when :success
                Rainbow("[DONE]\n").green
              when :failure
                Rainbow("[FAILED]\n").red
              when :skipped
                Rainbow("[SKIPPED]\n").yellow
              else
                raise ArgumentError, "State must be one of the following: #{STATES.join(', ')}"
              end

            self.print(output)
            flush!
          end

          # Display warning content on a new line with default formatting (stderr)
          #
          # @param [String] content
          def warning(content)
            self.puts("#{ICONS[:warning]} #{content}", stderr: true)
          end

          # Display error content on a new line with default formatting (stderr)
          #
          # @param [String] content
          def error(content)
            self.puts("#{ICONS[:error]} #{content}", stderr: true)
          end

          # Display provided content in a new line with a timestamp
          #
          # @param [String] content the content to be displayed
          # @param [Boolean] stderr when true outputs to stderr instead of stdout
          def puts(content, stderr: false)
            stderr ? warn(timestamp_format(content)) : $stdout.puts(timestamp_format(content))
          end

          # Display provided content in the current line with option to use a timestamp
          #
          # @param [String] content the content to be displayed
          # @param [Boolean] timestamp when true prepends content with a timestamp format
          def print(content, timestamp: false, stderr: false)
            output = stderr ? $stderr : $stdout
            output.print(timestamp ? timestamp_format(content) : content)
          end

          # Forces output to flush
          #
          # @param [Boolean] stderr
          def flush!(stderr: false)
            stderr ? $stderr.flush : $stdout.flush
          end

          private

          def timestamp_format(content)
            "[#{Time.now.utc}] #{content}"
          end
        end
      end
    end
  end
end
