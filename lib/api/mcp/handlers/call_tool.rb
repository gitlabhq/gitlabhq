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
          tool = find_tool!(params[:name])

          # only custom_service needs the current_user injected
          tool.set_cred(current_user: current_user) if tool.is_a? ::Mcp::Tools::CustomService

          tool.execute(request: request, params: params)
        end

        private

        attr_reader :manager

        def find_tool!(name)
          tool = manager.tools[name]
          raise ArgumentError, 'name is unsupported' unless tool

          tool
        end
      end
    end
  end
end
