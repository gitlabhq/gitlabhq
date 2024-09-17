# frozen_string_literal: true

require "tty-spinner"
require "stringio"

module Gitlab
  module Cng
    module Helpers
      # Spinner helper class for wrapping long running tasks in progress spinner
      #
      class Spinner
        include Output

        # Run code block inside spinner
        #
        # @param [String] spinner_message message to print when spinner starts
        # @param [String] done_message message to print when spinner finishes
        # @param [Boolean] raise_on_error raise error if block raises an error
        # @param [Boolean] print_block_output print output generated within spinner block including nested spinners
        # @param [Proc] &block
        # @return [Object]
        def self.spin(spinner_message, done_message: "done", raise_on_error: true, print_block_output: true, &block)
          new(
            spinner_message,
            raise_on_error: raise_on_error,
            print_block_output: print_block_output
          ).spin(done_message, &block)
        end

        def initialize(spinner_message, raise_on_error: true, print_block_output: true)
          @spinner_message = spinner_message
          @raise_on_error = raise_on_error
          @print_block_output = print_block_output
        end

        # Run code block inside spinner and capture any output
        #
        # Spinner doesn't work with blocks producing output while it spins
        # so output is captured and printed after spinner is done
        #
        # @param [String] done_message
        # @return [Object]
        def spin(done_message = "done")
          original_stdout = start_spinner
          result = yield
          spinner_success(done_message, original_stdout)

          result
        rescue StandardError => e
          spinner_error(original_stdout)
          error_message = [
            "",
            colorize("=== block '#{spinner_message}' error ===", :magenta),
            colorize(e.message&.strip, error_color),
            colorize("=== block '#{spinner_message}' error ===", :magenta)
          ].join("\n")
          return result unless raise_on_error

          raise(e)
        ensure
          puts_with_offset(original_stdout, $stdout.string) if print_block_output && !$stdout.string.empty?
          puts_with_offset(original_stdout, error_message) if error_message

          $stdout = original_stdout
          spinner_stack.pop
        end

        private

        attr_reader :spinner_message, :raise_on_error, :print_block_output

        # Error message color
        #
        # @return [Symbol]
        def error_color
          @error_color ||= raise_on_error ? :red : :yellow
        end

        # Success mark
        #
        # @return [String]
        def success_mark
          @success_mark ||= colorize(TTY::Spinner::TICK, :green)
        end

        # Error mark
        #
        # @return [String]
        def error_mark
          colorize(TTY::Spinner::CROSS, error_color)
        end

        # Spinner instance
        #
        # @return [TTY::Spinner]
        def spinner
          @spinner ||= TTY::Spinner.new(
            "[:spinner] #{spinner_message} ...",
            format: :dots,
            success_mark: success_mark,
            error_mark: error_mark
          )
        end

        # Currently running spinner stack
        #
        # @return [Array]
        def spinner_stack
          self.class.instance_variable_get(:@spinner_stack) || self.class.instance_variable_set(:@spinner_stack, [])
        end

        # Is currently running spinner nested
        #
        # @return [Boolean]
        def nested_spinner?
          spinner_stack.size > 1
        end

        # Check tty and nested spinner
        # Nested spinners override $stdout which won't be tty so we need to return false
        #
        # @return [Boolean]
        def tty?
          spinner.send(:tty?) && !nested_spinner? # rubocop:disable GitlabSecurity/PublicSend -- method is public on master branch but not released yet
        end

        # Start spinner instance and reassing stdout
        #
        # @return [IO]
        def start_spinner
          original_stdout = $stdout
          $stdout = StringIO.new
          spinner_stack << self

          spinner.auto_spin if tty?

          original_stdout
        end

        # Return spinner success
        #
        # @param [String] done_message
        # @param [IO] io
        # @return [void]
        def spinner_success(done_message, io)
          return spinner.success(done_message) if tty?

          spinner.stop if spinner.spinning?
          puts_with_offset(io, "[#{success_mark}] #{spinner_message} ... #{done_message}")
        end

        # Return spinner error
        #
        # @param [StandardError] error
        # @param [IO] io
        # @return [void]
        def spinner_error(io)
          done_message = colorize("failed", error_color)
          return spinner.error(done_message) if tty?

          spinner.stop if spinner.spinning?
          puts_with_offset(io, "[#{error_mark}] #{spinner_message} ... #{done_message}")
        end

        # Print output with a leading offset for correct nested spinner display
        #
        # @param [IO] io
        # @param [String] message
        # @return [void]
        def puts_with_offset(io, message)
          offset = nested_spinner? ? "  " : ""
          io.puts(message.split("\n").map { |line| "#{offset}#{line}" }.join("\n"))
        end
      end
    end
  end
end
