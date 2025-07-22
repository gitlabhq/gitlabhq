# frozen_string_literal: true

module API
  module Mcp
    module Handlers
      # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#initializednotification
      class InitializedNotificationRequest < Base
        def invoke
          # JSON-RPC notifications are one-way messages
          nil
        end
      end
    end
  end
end
