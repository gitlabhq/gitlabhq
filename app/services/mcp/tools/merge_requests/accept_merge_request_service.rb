# frozen_string_literal: true

module Mcp
  module Tools
    module MergeRequests
      class AcceptMergeRequestService < Base::GraphqlService
        register_version '0.1.0', {
          description: 'Merge a merge request, or schedule it to merge automatically. Without ' \
            'strategy the merge starts immediately and completes asynchronously; with strategy, ' \
            'auto-merge is armed and the merge request merges once its checks pass. Identify the ' \
            'merge request by url, or by project_id and merge_request_iid. To approve a merge ' \
            'request instead, use save_merge_request_review.',
          annotations: {
            readOnlyHint: false,
            destructiveHint: true
          },
          input_schema: {
            type: 'object',
            properties: {
              url: {
                type: 'string',
                description: 'GitLab URL of the merge request. Provide this, or project_id and merge_request_iid.'
              },
              project_id: {
                type: 'string',
                description: 'ID or path of the project. Required if url is not provided.'
              },
              merge_request_iid: {
                type: 'integer',
                description: 'Internal ID of the merge request. Required if url is not provided.'
              },
              sha: {
                type: 'string',
                description: 'Head SHA guard. When it no longer matches the merge request head, the ' \
                  'merge is refused instead of merging content you have not seen. Pass the ' \
                  'diff_head_sha returned by get_merge_request.'
              },
              strategy: {
                type: 'string',
                enum: ::AutoMergeService.all_strategies_ordered_by_preference,
                description: 'Auto-merge strategy. When given, arms auto-merge instead of merging ' \
                  'immediately.'
              },
              squash: {
                type: 'boolean',
                description: 'Squash the commits into a single commit on merge.'
              },
              commit_message: {
                type: 'string',
                description: 'Custom merge commit message.'
              },
              squash_commit_message: {
                type: 'string',
                description: 'Custom squash commit message. Applies when squash is true.'
              },
              should_remove_source_branch: {
                type: 'boolean',
                description: 'Remove the source branch after merging.'
              }
            },
            required: %w[sha]
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::MergeRequests::AcceptMergeRequestTool
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
