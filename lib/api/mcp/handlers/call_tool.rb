# frozen_string_literal: true

module API
  module Mcp
    module Handlers
      # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#calltoolrequest
      class CallTool
        def initialize(manager)
          @manager = manager
        end

        def invoke(request, params, current_user = nil)
          name = params[:name]

          begin
            tool = manager.get_tool(name: name)
          rescue ::Mcp::Tools::Manager::ToolNotFoundError => e
            raise ArgumentError, e.message
          end

          tool.set_cred(current_user: current_user) if tool.is_a?(::Mcp::Tools::CustomService)

          tool.execute(request: request, params: params)
        end

        private

        attr_reader :manager
      end
    end
  end
end
