# frozen_string_literal: true

module API
  module Mcp
    module Handlers
      # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#listtoolsrequest
      class ListTools
        def initialize(manager)
          @manager = manager
        end

        def invoke
          tools = manager.tools.map do |name, tool|
            {
              name: name,
              description: tool.description,
              inputSchema: tool.input_schema
            }
          end

          { tools: tools }
        end

        private

        attr_reader :manager
      end
    end
  end
end
