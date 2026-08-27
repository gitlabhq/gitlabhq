# frozen_string_literal: true

module Mcp
  module Tools
    module Commits
      class GetCommitService < Base::GraphqlService
        register_version '0.1.0', {
          description: 'Get a single commit\'s metadata, optionally including its diff or notes. ' \
            'Identify the commit with either url, or project_id and commit_sha.',
          input_schema: {
            type: 'object',
            required: [],
            properties: {
              url: {
                type: 'string',
                description: 'GitLab URL of the commit. Provide this, or project_id and commit_sha.'
              },
              project_id: {
                type: 'string',
                description: 'ID or path of the project. Required if url is not provided.'
              },
              commit_sha: {
                type: 'string',
                description: 'Commit to look up. Accepts a full or short SHA, branch name, or tag name. ' \
                  'Required if url is not provided.'
              },
              include: {
                type: 'array',
                description: 'Associated facet to fetch inline, one per call. "diff" returns the commit diff ' \
                  '(bounded by diff_detail); "notes" returns the commit notes (paginated with ' \
                  'notes_after/notes_first).',
                items: {
                  type: 'string',
                  enum: %w[diff notes]
                },
                maxItems: 1
              },
              diff_detail: {
                type: 'string',
                description: 'Level of diff detail to return. Applies only when "diff" is in include. ' \
                  '"stats" returns per-file and summary line counts; "full_patch" returns the patch text. ' \
                  'Defaults to "stats".',
                enum: %w[stats full_patch]
              },
              **Mcp::Tools::Concerns::CursorPagination.input_schema_params(
                items: 'notes',
                prefix: 'notes_',
                applies_to: 'notes is in include',
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
          Mcp::Tools::Commits::GetCommitTool
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
