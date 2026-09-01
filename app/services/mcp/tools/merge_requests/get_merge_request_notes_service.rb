# frozen_string_literal: true

module Mcp
  module Tools
    module MergeRequests
      class GetMergeRequestNotesService < Base::GraphqlService
        override :tool_aliases
        def self.tool_aliases
          ['list_all_merge_request_notes']
        end

        register_version '0.1.0', {
          description: 'Get the notes (comments and system notes) for a specific merge request.',
          input_schema: {
            type: 'object',
            required: [],
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
              **Mcp::Tools::Concerns::CursorPagination.input_schema_params(
                items: 'notes',
                params: %i[first last after before],
                default_page_size: nil
              )
            }
          },
          annotations: {
            readOnlyHint: true
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::MergeRequests::GetMergeRequestNotesTool
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
