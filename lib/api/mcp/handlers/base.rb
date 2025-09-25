# frozen_string_literal: true

module API
  module Mcp
    module Handlers
      class Base
        # NOTE: Tool execution needs OAuth token w/ mcp scope for authenticated REST API requests.
        # This creates two authentication layers:
        #   1. MCP endpoint authentication
        #   2. REST API endpoint(s) authentication (i.e. when MCP tool performs API calls)
        # Since OAuth token only has 'mcp' scope instead of 'api' scope, REST API endpoints exposed
        # as tools must include ::API::Concerns::McpAccess. As a result, MCP tokens can only access
        # specific API endpoints needed for tools rather than being granted full API access.
        attr_reader :access_token, :current_user, :params

        def initialize(params, access_token, current_user)
          @params = params
          @access_token = access_token
          @current_user = current_user
        end

        def invoke
          raise NoMethodError
        end
      end
    end
  end
end
