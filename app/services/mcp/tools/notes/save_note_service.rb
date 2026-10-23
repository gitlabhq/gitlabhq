# frozen_string_literal: true

module Mcp
  module Tools
    module Notes
      class SaveNoteService < Base::GraphqlService
        extend ::Gitlab::Utils::Override

        IDENTIFICATION_PARAMS = %i[url project_id group_id merge_request_iid work_item_iid].freeze

        METHOD_PARAMS = {
          'create_note' => { required: %i[body], optional: %i[internal] },
          'reply_discussion' => { required: %i[body discussion_id], optional: %i[internal] },
          'resolve_discussion' => { required: %i[discussion_id resolved], optional: [] }
        }.freeze

        register_version '0.1.0', {
          toolset: :core,
          description: 'Add a comment to a GitLab merge request or work item, reply to an existing ' \
            'discussion thread, or resolve or unresolve a discussion thread. Identify the target with url, ' \
            'or with merge_request_iid or work_item_iid plus its project_id or group_id',
          annotations: {
            title: 'Add comment',
            readOnlyHint: false,
            destructiveHint: false,
            idempotentHint: false,
            openWorldHint: false
          },
          input_schema: {
            type: 'object',
            properties: {
              url: {
                type: 'string',
                description: 'GitLab URL of a merge request or work item, including issues and epics ' \
                  '(.../-/merge_requests/<iid>, .../-/work_items/<iid>, .../-/issues/<iid>, or ' \
                  '.../groups/<full_path>/-/epics/<iid>). Issue URLs are project-scoped; epic URLs are group-scoped ' \
                  'and must include the groups/ prefix. ' \
                  'The URL determines the target type, so no other identifier is needed'
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
              method: {
                type: 'string',
                enum: %w[create_note reply_discussion resolve_discussion],
                description: 'The write operation to perform. Defaults to create_note, or to reply_discussion ' \
                  'when discussion_id is given. Fill only the parameters listed for the chosen method; ' \
                  'other parameters are rejected.'
              },
              body: {
                type: 'string',
                description: 'Content of the note/comment (create_note, reply_discussion; max ' \
                  "#{Concerns::Constants::MARKDOWN_TEXT_MAX_LENGTH} characters). Lines beginning with " \
                  '"/" are rejected to avoid triggering quick actions such as /merge',
                maxLength: Concerns::Constants::MARKDOWN_TEXT_MAX_LENGTH
              },
              internal: {
                type: 'boolean',
                description: 'Mark note as internal (visible only to members with at least the Reporter role)'
              },
              discussion_id: {
                type: 'string',
                description: 'Discussion to reply to (reply_discussion) or to resolve or unresolve ' \
                  '(resolve_discussion). Accepts the global ID (gid://gitlab/Discussion/<id>) or the bare <id>. ' \
                  'If omitted, creates a new top-level note'
              },
              resolved: {
                type: 'boolean',
                description: 'true resolves the discussion, false unresolves it (resolve_discussion)'
              }
            }
          }
        }

        override :tool_aliases
        def self.tool_aliases
          %w[create_merge_request_note create_workitem_note create_work_item_note]
        end

        protected

        def graphql_tool_class
          Mcp::Tools::Notes::SaveNoteTool
        end

        def perform_v0_1_0(arguments)
          validate_method_arguments!(arguments)

          execute_graphql_tool(arguments)
        end

        override :perform_default
        def perform_default(arguments = {})
          perform_v0_1_0(arguments)
        end

        private

        def validate_method_arguments!(arguments)
          method = arguments[:method] || (arguments[:discussion_id] ? 'reply_discussion' : 'create_note')
          rules = METHOD_PARAMS.fetch(method)

          missing = rules[:required].select { |key| arguments[key].nil? }
          raise ArgumentError, "Missing required parameters for #{method}: #{missing.join(', ')}" if missing.any?

          allowed = IDENTIFICATION_PARAMS + [:method] + rules[:required] + rules[:optional]
          extra = arguments.keys.map(&:to_sym) - allowed
          return if extra.none?

          raise ArgumentError, "Parameters not valid for method '#{method}': #{extra.join(', ')}"
        end
      end
    end
  end
end
