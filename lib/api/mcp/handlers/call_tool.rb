# frozen_string_literal: true

module API
  module Mcp
    module Handlers
      # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#calltoolrequest
      class CallTool
        def initialize(manager)
          @manager = manager
        end

        def invoke(request, params)
          tool = find_tool!(params[:name])
          tool.execute(request, params)
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
