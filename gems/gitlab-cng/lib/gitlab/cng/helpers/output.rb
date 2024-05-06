# frozen_string_literal: true

require "rainbow"

module Gitlab
  module Cng
    module Helpers
      # Console output helpers to include in command implementations
      #
      module Output
        private

        # Print base output without specific color
        #
        # @param [String] message
        # @param [Boolean] bright
        # @return [void]
        def log(message, bright: false)
          puts colorize(message, nil, bright: bright)
        end

        # Print info in magenta color
        #
        # @param [String] message
        # @param [Boolean] bright
        # @return [nil]
        def log_info(message, bright: false)
          puts colorize(message, :magenta, bright: bright)
        end

        # Print success message in green color
        #
        # @param [String] message
        # @param [Boolean] bright
        # @return [nil]
        def log_success(message, bright: false)
          puts colorize(message, :green, bright: bright)
        end

        # Print warning message in yellow color
        #
        # @param [String] message
        # @param [Boolean] bright
        # @return [nil]
        def log_warn(message, bright: false)
          puts colorize(message, :yellow, bright: bright)
        end

        # Print error message in red color
        #
        # @param [String] message
        # @param [Boolean] bright
        # @return [nil]
        def log_error(message, bright: false)
          puts colorize(message, :red, bright: bright)
        end

        # Exit with non zero exit code and print error message
        #
        # @param [String] message
        # @return [void]
        def exit_with_error(message)
          log_error(message, bright: true)
          exit 1
        end

        # Colorize message string and output to stdout
        #
        # @param [String] message
        # @param [<Symbol, nil>] color
        # @param [Boolean] bright
        # @return [String]
        def colorize(message, color, bright: false)
          rainbow.wrap(message)
            .then { |m| bright ? m.bright : m }
            .then { |m| color ? m.color(color) : m }
        end

        # Instance of rainbow colorization class
        #
        # @return [Rainbow]
        def rainbow
          @rainbow ||= Rainbow.new
        end
      end
    end
  end
end
