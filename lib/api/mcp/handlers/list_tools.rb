# frozen_string_literal: true

module API
  module Mcp
    module Handlers
      # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#listtoolsrequest
      class ListTools
        def initialize(manager)
          @manager = manager
        end

        def invoke(current_user)
          tools_hash = manager.list_tools

          tools = tools_hash.filter_map do |name, tool|
            next nil unless tool_available?(tool, current_user)

            {
              name: name,
              description: tool.description,
              inputSchema: tool.input_schema
            }
          end

          { tools: tools }
        end

        private

        def tool_available?(tool, current_user)
          # tool does not have an availability check if it does not inherit `Mcp::Tools::BaseService`
          return true unless tool.is_a?(::Mcp::Tools::BaseService)

          tool.set_cred(current_user: current_user) if tool.is_a? ::Mcp::Tools::CustomService
          tool.available?
        end

        attr_reader :manager
      end
    end
  end
end
