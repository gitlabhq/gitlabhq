# frozen_string_literal: true

module Mcp
  module Tools
    module Notes
      class SaveNoteService < Base::GraphqlService
        extend ::Gitlab::Utils::Override

        register_version '0.1.0', {
          description: 'Add a comment to a GitLab merge request or work item, or reply to an existing ' \
            'discussion thread. Identify the target with url, or with merge_request_iid or work_item_iid ' \
            'plus its project_id or group_id',
          annotations: {
            readOnlyHint: false,
            destructiveHint: false
          },
          input_schema: {
            type: 'object',
            properties: {
              url: {
                type: 'string',
                description: 'GitLab URL of the merge request or work item. The URL determines the target ' \
                  'type, so no other identifier is needed'
              },
              project_id: {
                type: 'string',
                description: 'ID or path of the project. Required with merge_request_iid, and with ' \
                  'work_item_iid for project-level work items'
              },
              group_id: {
                type: 'string',
                description: 'ID or path of the group. Required with work_item_iid for group-level work items'
              },
              merge_request_iid: {
                type: 'integer',
                description: 'Internal ID of the merge request. Provide with project_id. Mutually exclusive ' \
                  'with work_item_iid'
              },
              work_item_iid: {
                type: 'integer',
                description: 'Internal ID of the work item. Provide with project_id or group_id. Mutually ' \
                  'exclusive with merge_request_iid'
              },
              body: {
                type: 'string',
                description: 'Content of the note/comment (max 1,048,576 characters). Lines beginning with ' \
                  '"/" are rejected to avoid triggering quick actions such as /merge',
                maxLength: 1_048_576
              },
              internal: {
                type: 'boolean',
                description: 'Mark note as internal (visible only to members with at least the Reporter role)',
                default: false
              },
              discussion_id: {
                type: 'string',
                description: 'Global ID of the discussion to reply to (format: gid://gitlab/Discussion/<id>). ' \
                  'If omitted, creates a new top-level note'
              }
            },
            required: %w[body]
          }
        }

        override :tool_aliases
        def self.tool_aliases
          %w[create_merge_request_note create_workitem_note]
        end

        protected

        def graphql_tool_class
          Mcp::Tools::Notes::SaveNoteTool
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
