# frozen_string_literal: true

module QA
  module Vendor
    module Smocker
      class VerifyResponse
        def initialize(payload)
          @payload = payload
        end

        # Check if session did not have any errors
        #
        # @return [Boolean]
        def success?
          payload.dig(:mocks, :verified) && payload.dig(:history, :verified)
        end

        # Check if all mock definitions have been used
        #
        # @return [Boolean]
        def all_used?
          payload.dig(:mocks, :all_used)
        end

        # Fetch failures
        #
        # @return [Array]
        def failures
          (payload.dig(:mocks, :failures) || []) + (payload.dig(:history, :failures) || [])
        end

        # Fetch unused mock definitions
        #
        # @return [Array]
        def unused
          payload.dig(:mocks, :unused)
        end

        private

        # @return [Hash]
        attr_reader :payload
      end
    end
  end
end
