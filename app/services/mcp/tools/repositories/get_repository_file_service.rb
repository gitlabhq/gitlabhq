# frozen_string_literal: true

module Mcp
  module Tools
    module Repositories
      class GetRepositoryFileService < Base::GraphqlService
        MAX_LIMIT = ::Mcp::Tools::Repositories::GetRepositoryFileTool::MAX_LIMIT
        DEFAULT_LIMIT = ::Mcp::Tools::Repositories::GetRepositoryFileTool::DEFAULT_LIMIT

        register_version '0.1.0', {
          description: 'Read a file from a GitLab repository at a given ref. Reads from GitLab, not the local ' \
            'filesystem: use it for a project you have not checked out, or a specific branch, tag, or commit — ' \
            'not your local working copy. Returns the file as committed at ref. For large files, use offset and ' \
            'limit to read in windows; when the response is partial, system_instruction gives the next offset.',
          input_schema: {
            type: 'object',
            required: [],
            properties: {
              url: {
                type: 'string',
                description: 'GitLab URL of the file, for example ' \
                  'https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/user.rb. ' \
                  'Provide this, or project_id, file_path, and ref.'
              },
              project_id: {
                type: 'string',
                description: 'ID or full path of the project. Required if url is not provided.'
              },
              file_path: {
                type: 'string',
                description: 'Path of the file relative to the repository root, for example ' \
                  'app/models/user.rb. Required if url is not provided.'
              },
              ref: {
                type: 'string',
                description: 'Branch name, tag name, or commit SHA. Use HEAD for the default branch. ' \
                  'Required if url is not provided. Overrides any ref in url.'
              },
              offset: {
                type: 'integer',
                description: 'Zero-indexed line number to start reading from. Defaults to 0.',
                minimum: 0
              },
              limit: {
                type: 'integer',
                description: "Maximum number of lines to return. Defaults to #{DEFAULT_LIMIT}; " \
                  "the maximum is #{MAX_LIMIT}.",
                minimum: 1,
                maximum: MAX_LIMIT
              }
            }
          },
          annotations: {
            readOnlyHint: true
          }
        }

        protected

        def graphql_tool_class
          ::Mcp::Tools::Repositories::GetRepositoryFileTool
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
