# frozen_string_literal: true

module Mcp
  module Tools
    module Labels
      class GraphqlSearchService < GraphqlService
        register_version '0.1.0', {
          description: 'Search labels in a GitLab project or group',
          input_schema: {
            type: 'object',
            properties: {
              # Label search identification (one set required)
              full_path: {
                type: 'string',
                description: 'Full path of the project or group. Required.'
              },
              is_project: {
                type: 'boolean',
                description: 'Whether to search in a project (true) or group (false). Required.'
              },
              search: {
                type: 'string',
                description: 'Search term to filter labels by title.'
              }
            },
            required: %w[full_path is_project]
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::Labels::SearchTool
        end

        def perform_0_1_0(arguments)
          execute_graphql_tool(arguments)
        end

        override :perform_default
        def perform_default(arguments = {})
          perform_0_1_0(arguments)
        end
      end
    end
  end
end
