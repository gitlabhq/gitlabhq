# frozen_string_literal: true

module Mcp
  module Tools
    module MergeRequests
      class GetMergeRequestService < Base::GraphqlService
        register_version '0.1.0', {
          description: 'Get a merge request and optionally its diffs, commits, notes, pipelines, or discussions. ' \
            'By default only the base merge request metadata is returned; request associated data through the ' \
            '`include` parameter so nothing extra is fetched unless asked for.',
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
              include: {
                type: 'array',
                description: 'Associated facets to fetch inline, one per call. diffs returns change ' \
                  'stats only (totals and per-file additions and deletions), not patch text: use the ' \
                  'get_merge_request_diffs tool for patch text and get_merge_request_conflicts for conflicts. ' \
                  'notes supports pagination (notes_after/notes_first).',
                items: {
                  type: 'string',
                  enum: %w[diffs commits notes pipelines discussions]
                },
                maxItems: 1
              },
              notes_after: {
                type: 'string',
                description: 'Cursor for forward pagination of notes. ' \
                  'Use endCursor from a previous response. Applies only when notes is in include.'
              },
              notes_first: {
                type: 'integer',
                description: 'Number of notes to return after the cursor (max 100). ' \
                  'Applies only when notes is in include.',
                minimum: 1,
                maximum: 100
              }
            }
          },
          annotations: {
            readOnlyHint: true
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::MergeRequests::GetMergeRequestTool
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
