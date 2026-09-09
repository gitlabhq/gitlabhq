# frozen_string_literal: true

module API
  module Helpers
    module Mcp
      # Shared JSON-RPC helpers used by both MCP API endpoints.
      module JsonRpc
        # Echoing the id lets a caller match this response to its request.
        # The JSON-RPC spec only allows a string, a whole number, or null for the id,
        # so anything else (an object, a float, a boolean) comes back as null.
        # See: https://www.jsonrpc.org/specification#response_object
        def jsonrpc_request_id
          id = params[:id]

          id if id.is_a?(Integer) || id.is_a?(String)
        end
      end
    end
  end
end
