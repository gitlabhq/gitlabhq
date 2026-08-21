# frozen_string_literal: true

module Mcp
  module Tools
    module Repositories
      class ListRepositoryTreeService < Base::GraphqlService
        register_version '0.1.0', {
          description: 'List files and directories in a GitLab repository at a given path and ref. ' \
            'Identify the project with exactly one of url or project_id. Returns entry metadata only, ' \
            'never file contents; use get_repository_file to read a file. Each call returns up to 100 ' \
            'entries; when pageInfo.hasNextPage is true, pass pageInfo.endCursor as after to fetch the ' \
            'next page.',
          input_schema: {
            type: 'object',
            required: [],
            properties: {
              url: {
                type: 'string',
                description: 'GitLab URL of the project. Provide exactly one of url or project_id.'
              },
              project_id: {
                type: 'string',
                description: 'Project ID or full path. Provide exactly one of url or project_id.'
              },
              path: {
                type: 'string',
                description: 'Path of the directory to list, relative to the repository root. ' \
                  'Defaults to the root.'
              },
              ref: {
                type: 'string',
                description: 'Branch name, tag name, or commit SHA. Defaults to HEAD, the default branch.'
              },
              recursive: {
                type: 'boolean',
                description: 'When true, lists entries of all subdirectories recursively. Defaults to false.'
              },
              after: {
                type: 'string',
                description: 'Cursor for forward pagination. Use endCursor from the previous response.'
              }
            }
          },
          annotations: {
            readOnlyHint: true
          }
        }

        protected

        def graphql_tool_class
          ::Mcp::Tools::Repositories::ListRepositoryTreeTool
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
