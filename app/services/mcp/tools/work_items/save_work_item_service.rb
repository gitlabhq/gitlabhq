# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class SaveWorkItemService < Base::GraphqlService
        extend ::Gitlab::Utils::Override

        # Issue and epic URLs must route to update so an unrecognized item URL fails
        # URL parsing instead of silently creating a duplicate work item.
        UPDATE_INTENT_URL = %r{/-/(?:work_items|issues|epics)/\d+(?:[/?#]|\z)}

        register_version '0.1.0', {
          description: <<~DESC.strip,
            Create or update a GitLab work item, such as an issue, task, or epic.
            Omit work_item_iid to create a new work item; provide work_item_iid or a
            work item URL to update an existing one. Send only the fields you intend
            to set, and omit the rest.
          DESC
          annotations: {
            readOnlyHint: false,
            destructiveHint: false
          },
          input_schema: {
            type: 'object',
            properties: {
              url: {
                type: 'string',
                description: 'GitLab URL for the project, group, or work item. ' \
                  'Provide exactly one of url, project_id, or group_id.'
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
                description: 'Positive internal ID of the work item to update. Omit to create a new work item.'
              },
              title: {
                type: 'string',
                description: 'Title. Required on create.'
              },
              type_name: {
                type: 'string',
                description: 'Work item type name, for example "Issue", "Task", "Epic". Required on create. ' \
                  'Valid types depend on the namespace and license; invalid values return the list of valid ones.'
              },
              description: {
                type: 'string',
                description: 'Description in GitLab Flavored Markdown (max 1,048,576 characters).',
                maxLength: 1_048_576
              },
              assignee_ids: {
                type: 'array',
                items: { type: 'integer' },
                maxItems: 100,
                description: 'User IDs to assign to the work item.'
              },
              label_ids: {
                type: 'array',
                items: { type: 'string' },
                maxItems: 100,
                description: 'Label IDs or global IDs. Create only; on update use add_label_ids/remove_label_ids.'
              },
              add_label_ids: {
                type: 'array',
                items: { type: 'string' },
                maxItems: 100,
                description: 'Update only. Label IDs or global IDs to add.'
              },
              remove_label_ids: {
                type: 'array',
                items: { type: 'string' },
                maxItems: 100,
                description: 'Update only. Label IDs or global IDs to remove.'
              },
              confidential: {
                type: 'boolean',
                description: 'Sets the work item confidentiality.'
              },
              start_date: {
                type: 'string',
                description: 'Start date, YYYY-MM-DD.'
              },
              due_date: {
                type: 'string',
                description: 'Due date, YYYY-MM-DD.'
              },
              state: {
                type: 'string',
                enum: %w[opened closed],
                description: 'Update only. closed closes the work item, opened reopens it.'
              },
              parent_id: {
                type: 'string',
                description: 'Global ID or numeric ID of the parent work item (hierarchy).'
              },
              todo_action: {
                type: 'string',
                enum: %w[add mark_as_done],
                description: 'Update only. add adds a to-do for the current user, ' \
                  'mark_as_done marks to-dos as done.'
              },
              todo_id: {
                type: 'string',
                description: 'Update only. Global ID or numeric ID of the to-do; ' \
                  'omit to update all to-dos on the work item.'
              }
            },
            required: []
          }
        }

        override :tool_aliases
        def self.tool_aliases
          %w[create_work_item update_work_item]
        end

        protected

        def perform_v0_1_0(arguments)
          tool = tool_class(arguments).new(
            current_user: current_user,
            params: arguments,
            version: version
          )

          tool.execute
        end

        override :perform_default
        def perform_default(arguments = {})
          perform_v0_1_0(arguments)
        end

        private

        def tool_class(arguments)
          return Mcp::Tools::WorkItems::UpdateWorkItemTool if update?(arguments)

          Mcp::Tools::WorkItems::CreateWorkItemTool
        end

        def update?(arguments)
          # Not present?: integer 0 is Rails-present, but zero-filling clients
          # send work_item_iid: 0 meaning "unset", and iids start at 1.
          arguments[:work_item_iid].to_i > 0 || arguments[:url].to_s.match?(UPDATE_INTENT_URL)
        end
      end
    end
  end
end

Mcp::Tools::WorkItems::SaveWorkItemService.prepend_mod
