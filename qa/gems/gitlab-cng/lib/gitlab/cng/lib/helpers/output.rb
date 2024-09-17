# frozen_string_literal: true

require "rainbow"

module Gitlab
  module Cng
    module Helpers
      # Console output helpers to include in command implementations
      #
      module Output
        LOG_COLOR = {
          default: nil,
          info: :magenta,
          success: :green,
          warn: :yellow,
          error: :red
        }.freeze

        class << self
          # Global instance of rainbow colorization class
          #
          # @return [Rainbow]
          def rainbow
            @rainbow ||= Rainbow.new.tap { |rb| rb.enabled = true if @force_color }
          end

          # Force color output
          #
          # @return [Boolean]
          def force_color!
            @force_color = true
          end
        end

        private

        # Print colorized log message to stdout
        #
        # @param [String] message
        # @param [Symbol] type
        # @param [Boolean] bright
        # @return [void]
        def log(message, type = :default, bright: false)
          puts colorize(message, LOG_COLOR.fetch(type), bright: bright)
        end

        # Exit with non zero exit code and print error message
        #
        # @param [String] message
        # @return [void]
        def exit_with_error(message)
          log(message, :error, bright: true)
          exit 1
        end

        # Colorize message string and output to stdout
        #
        # @param [String] message
        # @param [<Symbol, nil>] color
        # @param [Boolean] bright
        # @return [String]
        def colorize(message, color, bright: false)
          Output.rainbow.wrap(message)
            .then { |m| bright ? m.bright : m }
            .then { |m| color ? m.color(color) : m }
        end

        # Remove sensitive data from message
        #
        # @param [String] message
        # @param [Array<String>] secrets
        # @return [String]
        def mask_secrets(message, secrets)
          # Add explicit arg validation to avoid values leaking to error outputs in case of errors
          raise ArgumentError, "message must be a string" unless message.is_a?(String)
          raise ArgumentError, "secrets must be an array of strings" unless secrets.is_a?(Array) && secrets.all?(String)

          message.gsub(/#{secrets.join('|')}/, "*****")
        end
      end
    end
  end
end
