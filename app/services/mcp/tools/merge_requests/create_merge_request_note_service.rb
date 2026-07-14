# frozen_string_literal: true

module Mcp
  module Tools
    module MergeRequests
      class CreateMergeRequestNoteService < Base::GraphqlService
        register_version '0.1.0', {
          description: 'Add a new comment or reply to an existing discussion on a GitLab merge request ' \
            'as the authenticated user. To reply within a thread, pass the discussion_id ' \
            'returned by get_merge_request_notes.',
          annotations: {
            readOnlyHint: false,
            destructiveHint: false
          },
          input_schema: {
            type: 'object',
            properties: {
              url: {
                type: 'string',
                description: 'GitLab URL of the merge request. ' \
                  'Provide this, or project_id and merge_request_iid.'
              },
              project_id: {
                type: 'string',
                description: 'ID or path of the project. Required if url is not provided.'
              },
              merge_request_iid: {
                type: 'integer',
                description: 'Internal ID of the merge request. Required if url is not provided.'
              },
              body: {
                type: 'string',
                description: 'Content of the note/comment (max 1,048,576 characters). Lines that begin with "/" ' \
                  'are rejected to avoid triggering quick actions such as /merge.',
                maxLength: 1_048_576
              },
              discussion_id: {
                type: 'string',
                description: 'Global ID of the discussion to reply to (format: gid://gitlab/Discussion/<id>). ' \
                  'If omitted, creates a new top-level note.'
              }
            },
            required: %w[body],
            additionalProperties: false
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::MergeRequests::CreateMergeRequestNoteTool
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
