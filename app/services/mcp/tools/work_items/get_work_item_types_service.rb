# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class GetWorkItemTypesService < Base::GraphqlService
        register_version '0.1.0', {
          description:
            'List the work item types available in a namespace (group or project), ' \
            'including system-defined types (Issue, Epic, Task, etc.) and custom types. ' \
            'Each returned type includes its global ID, name, icon, and the widget types enabled on it ' \
            'so the agent can avoid setting fields the type does not support.',
          input_schema: {
            type: 'object',
            properties: {
              url: {
                type: 'string',
                description: 'GitLab URL for the namespace (project or group).'
              },
              group_id: {
                type: 'string',
                description: 'ID or path of the group. Required if URL and project_id are not provided.'
              },
              project_id: {
                type: 'string',
                description: 'ID or path of the project. Required if URL and group_id are not provided.'
              }
            }
          },
          annotations: {
            readOnlyHint: true
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::WorkItems::GetWorkItemTypesTool
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

Mcp::Tools::WorkItems::GetWorkItemTypesService.prepend_mod
