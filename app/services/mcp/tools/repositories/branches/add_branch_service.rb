# frozen_string_literal: true

module Mcp
  module Tools
    module Repositories
      module Branches
        class AddBranchService < Base::GraphqlService
          extend ::Gitlab::Utils::Override

          register_version '0.1.0', {
            description: <<~DESC.strip,
              Add a branch to a GitLab project from a source ref.

              Examples:
              - Use branch and ref to create a new branch from an existing branch or commit SHA
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
                  description: 'GitLab URL of the project. Provide this, or project_id.'
                },
                project_id: {
                  type: 'string',
                  description: 'ID or path of the project. Required if url is not provided.'
                },
                branch: {
                  type: 'string',
                  description: 'Name of the new branch'
                },
                ref: {
                  type: 'string',
                  description: 'Branch name or commit SHA to create the new branch from'
                }
              },
              required: %w[branch ref],
              additionalProperties: false
            }
          }

          override :tool_aliases
          def self.tool_aliases
            ['create_branch']
          end

          protected

          def graphql_tool_class
            Mcp::Tools::Repositories::Branches::AddBranchTool
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
end

Mcp::Tools::Repositories::Branches::AddBranchService.prepend_mod
