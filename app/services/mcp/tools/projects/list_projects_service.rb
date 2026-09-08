# frozen_string_literal: true

module Mcp
  module Tools
    module Projects
      class ListProjectsService < Base::GraphqlService
        MIN_ACCESS_LEVELS = %w[guest planner reporter developer maintainer owner].freeze

        register_version '0.1.0', {
          description: 'List GitLab projects. Without group_id, defaults to projects you have at least ' \
            'guest access to; pass min_access_level to raise the threshold. With group_id, lists every ' \
            'project in that group and its subgroups regardless of access level; adding min_access_level ' \
            'or visibility narrows the listing to that group only, not its subgroups. When group_id is ' \
            'given, the response includes subgroupsIncluded so you know which case applied.',
          input_schema: {
            type: 'object',
            required: [],
            properties: {
              group_id: {
                type: 'string',
                description: 'ID or full path of a group.'
              },
              min_access_level: {
                type: 'string',
                description: 'Minimum access level a project must grant you to be included.',
                enum: MIN_ACCESS_LEVELS
              },
              search: {
                type: 'string',
                description: 'Search projects by name, path, or description.'
              },
              visibility: {
                type: 'string',
                description: 'Filter by visibility level.',
                enum: ::Gitlab::VisibilityLevel.string_options.keys
              },
              archived: {
                type: 'string',
                description: 'Filter by archived state: only returns archived projects, include ' \
                  'returns both, exclude returns only non-archived projects (default).',
                enum: %w[only include exclude]
              },
              **Mcp::Tools::Concerns::CursorPagination.input_schema_params(items: 'projects')
            }
          },
          annotations: {
            readOnlyHint: true
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::Projects::ListProjectsTool
        end

        def perform_v0_1_0(arguments)
          execute_graphql_tool(arguments)
        end

        override :perform_default
        def perform_default(arguments = {})
          perform_v0_1_0(arguments)
        end
      end
    end
  end
end
