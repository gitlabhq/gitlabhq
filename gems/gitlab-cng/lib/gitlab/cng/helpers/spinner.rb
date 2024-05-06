# frozen_string_literal: true

require "tty-spinner"

module Gitlab
  module Cng
    module Helpers
      # Spinner helper class
      #
      class Spinner
        include Output

        def initialize(spinner_message, raise_on_error: true)
          @spinner_message = spinner_message
          @raise_on_error = raise_on_error
        end

        # Run code block inside spinner
        #
        # @param [String] spinner_message
        # @param [String] done_message
        # @param [Boolean] exit_on_error
        # @param [Proc] &block
        # @return [Object]
        def self.spin(spinner_message, done_message: "done", raise_on_error: true, &block)
          new(spinner_message, raise_on_error: raise_on_error).spin(done_message, &block)
        end

        # Run code block inside spinner
        #
        # @param [String] done_message
        # @return [Object]
        def spin(done_message = "done")
          spinner.auto_spin
          result = yield
          spinner_success(done_message)

          result
        rescue StandardError => e
          spinner_error(e)
          return result unless raise_on_error

          raise(e)
        end

        private

        attr_reader :spinner_message, :raise_on_error

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

        # Check tty
        #
        # @return [Boolean]
        def tty?
          spinner.send(:tty?) # rubocop:disable GitlabSecurity/PublicSend -- method is public on master branch but not released yet
        end

        # Return spinner success
        #
        # @param [String] done_message
        # @return [void]
        def spinner_success(done_message)
          return spinner.success(done_message) if tty?

          spinner.stop
          puts("[#{success_mark}] #{spinner_message} ... #{done_message}")
        end

        # Return spinner error
        #
        # @param [StandardError] error
        # @return [void]
        def spinner_error(error)
          message = ["failed", error.message]

          colored_message = colorize(message.compact.join("\n"), error_color)
          return spinner.error(colored_message) if tty?

          spinner.stop
          puts("[#{error_mark}] #{spinner_message} ... #{colored_message}")
        end
      end
    end
  end
end
