# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class GetWorkItemService < Base::GraphqlService
        register_version '0.1.0', {
          description:
            'Get a single work item (issue, epic, task, incident, objective, key result) with its ' \
            'type, dates, assignees, labels, milestone, and parent. Optionally include its notes ' \
            'or the merge requests related to it. Identify the work item by url, or by ' \
            'work_item_iid plus group_id or project_id. Widgets the work item type does not ' \
            'support are omitted.',
          input_schema: {
            type: 'object',
            properties: {
              url: {
                type: 'string',
                description: 'GitLab URL of the work item (a /-/work_items/, /-/issues/, or /-/epics/ URL). ' \
                  'Provide this, or work_item_iid with group_id or project_id.'
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
                description: 'Internal ID of the work item. Required if url is not provided.'
              },
              include: {
                type: 'array',
                items: {
                  type: 'string',
                  enum: %w[notes related_merge_requests]
                },
                maxItems: 1,
                description: 'Associated data to return with the work item, one facet per call. ' \
                  'notes returns the first 100 notes; use get_workitem_notes for full note ' \
                  'pagination. related_merge_requests paginates with the parameters below and is ' \
                  'empty for group-level work items such as epics.'
              },
              **Mcp::Tools::Concerns::CursorPagination.input_schema_params(
                items: 'related merge requests',
                prefix: 'related_merge_requests_',
                applies_to: 'related_merge_requests is in include'
              ),
              mr_page_size: {
                type: 'integer',
                minimum: Mcp::Tools::Concerns::CursorPagination::MIN_PAGE_SIZE,
                maximum: Mcp::Tools::Concerns::CursorPagination::MAX_PAGE_SIZE,
                description: 'DEPRECATED: use related_merge_requests_first instead.'
              },
              mr_pagination_cursor: {
                type: 'string',
                description: 'DEPRECATED: use related_merge_requests_after instead.'
              }
            }
          },
          annotations: {
            readOnlyHint: true
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::WorkItems::GetWorkItemTool
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

Mcp::Tools::WorkItems::GetWorkItemService.prepend_mod
