# frozen_string_literal: true

module Mcp
  module Tools
    module Labels
      class SearchService < Base::GraphqlService
        container_arguments project_or_group: :full_path

        register_version '0.1.0', {
          toolset: :core,
          description: 'Search labels in a GitLab project or group',
          annotations: {
            readOnlyHint: true
          },
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

        register_version '0.2.0', {
          description: 'Search labels in a GitLab project or group by multiple terms',
          annotations: { readOnlyHint: true },
          toolset: :core,
          input_schema: {
            type: 'object',
            properties: {
              full_path: {
                type: 'string',
                description: 'Full path of the project or group. Required.'
              },
              is_project: {
                type: 'boolean',
                description: 'Whether to search in a project (true) or group (false). Required.'
              },
              search: {
                oneOf: [
                  { type: 'string' },
                  { type: 'array', items: { type: 'string' }, minItems: 1, maxItems: 10 }
                ],
                description: 'Search term, or up to 10 terms, to filter labels by title. Omit to list labels.'
              }
            },
            required: %w[full_path is_project]
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::Labels::SearchTool
        end

        def perform_v0_1_0(arguments)
          execute_graphql_tool(arguments)
        end

        def perform_v0_2_0(arguments)
          execute_graphql_tool(arguments)
        end

        override :perform_default
        def perform_default(arguments = {})
          perform_v0_2_0(arguments)
        end
      end
    end
  end
end
