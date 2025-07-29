# frozen_string_literal: true

module API
  module Mcp
    module Handlers
      # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#calltoolrequest
      class CallToolRequest < Base
        def invoke
          validate_params

          # TODO: Implement tools capabilities in lib/services
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/554828
          case params[:name]
          when 'get_mcp_server_version' # NOTE: Temporary mock tool for integration testing
            { content: [{ type: 'text', text: Gitlab::VERSION }], isError: false }
          else
            raise ArgumentError, 'tool name is unsupported'
          end
        end

        private

        def validate_params
          raise ArgumentError, 'name is missing' unless params[:name]
          raise ArgumentError, 'name is empty' if params[:name].blank?
        end
      end
    end
  end
end
