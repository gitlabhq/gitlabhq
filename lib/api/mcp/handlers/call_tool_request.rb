# frozen_string_literal: true

module API
  module Mcp
    module Handlers
      # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#calltoolrequest
      class CallToolRequest < Base
        def initialize(params, access_token)
          super(params)
          @access_token = access_token
        end

        def invoke
          validate_params

          tool_klass = ListToolsRequest::TOOLS[params[:name]]
          raise ArgumentError, 'name is unsupported' unless tool_klass

          tool = tool_klass.new(name: params[:name])

          begin
            tool.execute(access_token, params[:arguments])
          rescue StandardError => e
            # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#calltoolresult-iserror
            ::Mcp::Tools::Response.error(e.message)
          end
        end

        private

        # NOTE: Tool execution needs OAuth token w/ mcp scope for authenticated REST API requests.
        # This creates two authentication layers:
        #   1. MCP endpoint authentication
        #   2. REST API endpoint(s) authentication (i.e. when MCP tool performs API calls)
        # Since OAuth token only has 'mcp' scope instead of 'api' scope, REST API endpoints exposed
        # as tools must include ::API::Concerns::McpAccess. As a result, MCP tokens can only access
        # specific API endpoints needed for tools rather than being granted full API access.
        attr_reader :access_token

        def validate_params
          raise ArgumentError, 'name is missing' unless params[:name]
          raise ArgumentError, 'name is empty' if params[:name].blank?
        end
      end
    end
  end
end
