# frozen_string_literal: true

module API
  module Mcp
    module Handlers
      # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#calltoolrequest
      class CallToolRequest < Base
        def invoke
          validate_params

          tool_klass = ListToolsRequest::TOOLS[params[:name]]
          raise ArgumentError, 'name is unsupported' unless tool_klass

          tool = tool_klass.new(name: params[:name])
          tool.set_cred(current_user: current_user, access_token: access_token)

          begin
            tool.execute(params: params)
          rescue StandardError => e
            # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#calltoolresult-iserror
            ::Mcp::Tools::Response.error(e.message)
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
