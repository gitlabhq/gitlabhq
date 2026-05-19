# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class GraphqlLinkWorkItemsService < GraphqlService
        register_version '0.1.0', {
          description:
            'Link a work item to other work items with a relationship type (relates_to)',
          annotations: {
            readOnlyHint: false,
            destructiveHint: false
          },
          input_schema: {
            type: 'object',
            properties: {
              # Source work item identification (one set required)
              url: {
                type: 'string',
                description: 'GitLab URL for the source work item.'
              },
              group_id: {
                type: 'string',
                description: 'ID or path of the group. Required if URL and project_id are not provided.'
              },
              project_id: {
                type: 'string',
                description: 'ID or path of the project. Required if URL and group_id are not provided.'
              },
              work_item_iid: {
                type: 'integer',
                description: 'Internal ID of the source work item. Required if URL is not provided.'
              },

              # Target work items
              work_items_ids: {
                type: 'array',
                description:
                  'Global IDs of the work items to link to (format: gid://gitlab/WorkItem/<id>). Maximum 10 items.',
                items: {
                  type: 'string'
                },
                minItems: 1,
                maxItems: 10
              },

              # Relationship type
              link_type: {
                type: 'string',
                description: 'Type of relationship between the work items. Defaults to "relates_to".',
                enum: %w[relates_to],
                default: 'relates_to'
              }
            },
            required: ['work_items_ids']
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::WorkItems::LinkWorkItemsTool
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

Mcp::Tools::WorkItems::GraphqlLinkWorkItemsService.prepend_mod
