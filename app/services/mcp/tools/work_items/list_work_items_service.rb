# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class ListWorkItemsService < Base::GraphqlService
        # Stable, edition-independent subset of WorkItems::SortingKeys.all:
        # widget-derived keys vary by edition and license, so they are
        # excluded to keep the versioned schema identical on CE and EE.
        SORT_VALUES = ::WorkItems::SortingKeys::DEFAULT_SORTING_KEYS.keys.map { |key| key.to_s.upcase }.freeze
        TYPE_VALUES = ::Types::IssueTypeEnum.values.keys.freeze
        MAX_FILTER_VALUES = 100

        register_version '0.1.0', {
          description:
            "List or search work items (#{TYPE_VALUES.join(', ')}) " \
            'in a group or project. Filter by state, author, assignees, labels, milestone, dates, ' \
            'type, or free text. Group scope includes work items of descendant projects and ' \
            'subgroups. Each row carries only compact identifying fields: id, iid, title, state, ' \
            'web URL, reference, created and updated timestamps, and work item type. Use ' \
            'get_work_item for full details of one work item, including description, assignees, ' \
            'labels, and milestone.',
          input_schema: {
            type: 'object',
            properties: {
              url: {
                type: 'string',
                description: 'GitLab URL for the project or group.'
              },
              group_id: {
                type: 'string',
                description: 'ID or path of the group. Required if URL and project_id are not provided.'
              },
              project_id: {
                type: 'string',
                description: 'ID or path of the project. Required if URL and group_id are not provided.'
              },
              state: {
                type: 'string',
                enum: %w[opened closed all],
                description: 'Filter by state. Default is all.'
              },
              search: {
                type: 'string',
                description: 'Free-text search in title and description.'
              },
              author_username: {
                type: 'string',
                description: 'Username of the author.'
              },
              assignee_usernames: {
                type: 'array',
                items: { type: 'string' },
                maxItems: MAX_FILTER_VALUES,
                description: 'Usernames of assignees. A work item must match all of them.'
              },
              label_name: {
                type: 'array',
                items: { type: 'string' },
                maxItems: MAX_FILTER_VALUES,
                description: 'Label names. A work item must have all of them.'
              },
              milestone_title: {
                type: 'array',
                items: { type: 'string' },
                maxItems: MAX_FILTER_VALUES,
                description: 'Milestone titles. Cannot be combined with milestone_wildcard_id.'
              },
              milestone_wildcard_id: {
                type: 'string',
                enum: %w[NONE ANY STARTED UPCOMING],
                description: 'Milestone wildcard. Cannot be combined with milestone_title.'
              },
              types: {
                type: 'array',
                items: { type: 'string', enum: TYPE_VALUES },
                description: 'Work item types to include, for example ["ISSUE", "TASK"].'
              },
              created_after: {
                type: 'string',
                description: 'Created after this time (ISO 8601; date-only means start of day, offsets honored).'
              },
              created_before: {
                type: 'string',
                description: 'Created before this time (ISO 8601; date-only means start of day, offsets honored).'
              },
              updated_after: {
                type: 'string',
                description: 'Updated after this time (ISO 8601; date-only means start of day, offsets honored).'
              },
              updated_before: {
                type: 'string',
                description: 'Updated before this time (ISO 8601; date-only means start of day, offsets honored).'
              },
              due_after: {
                type: 'string',
                description: 'Due after this time (ISO 8601; date-only means start of day, offsets honored).'
              },
              due_before: {
                type: 'string',
                description: 'Due before this time (ISO 8601; date-only means start of day, offsets honored).'
              },
              sort: {
                type: 'string',
                enum: SORT_VALUES,
                description: 'Sort order. Default is CREATED_DESC.'
              },
              **Mcp::Tools::Concerns::CursorPagination.input_schema_params(items: 'work items')
            }
          },
          annotations: {
            readOnlyHint: true
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::WorkItems::ListWorkItemsTool
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

Mcp::Tools::WorkItems::ListWorkItemsService.prepend_mod
