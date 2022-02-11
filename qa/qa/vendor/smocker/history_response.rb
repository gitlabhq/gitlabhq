# frozen_string_literal: true

require_relative './event_payload'
require 'time'

module QA
  module Vendor
    module Smocker
      class HistoryResponse
        attr_reader :payload

        def initialize(payload)
          @payload = payload
        end

        # Smocker context including call counter
        def context
          payload[:context]
        end

        # Smocker request data
        def request
          payload[:request]
        end

        # @return [EventPayload] the request body as a webhook event
        def as_hook_event
          body = request&.dig(:body)
          EventPayload.new body if body
        end

        # @return [Time] Time request was recieved
        def received
          date = request&.dig(:date)
          Time.parse date if date
        end

        # Find time elapsed since <target>
        #
        # @param target [Time] target time
        # @return [Integer] seconds elapsed since <target>
        def elapsed(target)
          (received.to_f - target.to_f).round if received
        end

        def response
          payload[:response]
        end
      end
    end
  end
end
