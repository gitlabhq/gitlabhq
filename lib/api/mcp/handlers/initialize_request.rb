# frozen_string_literal: true

module API
  module Mcp
    module Handlers
      # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#initializerequest
      class InitializeRequest < Base
        def invoke
          {
            protocolVersion: '2025-06-18',
            capabilities: {
              tools: { listChanged: false }
            },
            serverInfo: {
              name: 'Official GitLab MCP Server',
              version: Gitlab::VERSION
            }
          }
        end
      end
    end
  end
end
