# frozen_string_literal: true

module API
  module Mcp
    module Handlers
      # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#listtoolsrequest
      class ListToolsRequest < Base
        def invoke
          {
            tools: mock_tools
          }
        end

        private

        # TODO: Implement tools capabilities in lib/services
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/554828
        def mock_tools
          [
            {
              name: 'get_mcp_server_version',
              description: 'Get the current version of MCP server',
              inputSchema: {
                type: 'object',
                properties: {},
                required: []
              }
            }
          ]
        end
      end
    end
  end
end
