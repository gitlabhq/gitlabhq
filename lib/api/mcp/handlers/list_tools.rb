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
            next nil if exclude_tool?(name, current_user)

            {
              name: name,
              description: tool.description,
              inputSchema: tool.input_schema
            }
          end

          { tools: tools }
        end

        private

        def exclude_tool?(tool_name, current_user)
          return Feature.disabled?(:code_snippet_search_graphqlapi, current_user) if tool_name == 'semantic_code_search'

          false
        end

        attr_reader :manager
      end
    end
  end
end
