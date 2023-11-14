# frozen_string_literal: true

module QA
  # Global options for test run
  #
  module Support
    class GlobalOptions
      class << self
        # Get global cli options
        #
        # @return [Hash]
        def get
          @options ||= {}
        end

        # Set global cli options
        #
        # @param [Hash] options
        # @return [Hash]
        def set(options)
          @options = options
        end
      end
    end
  end
end
