# frozen_string_literal: true

module Mcp
  module Tools
    module Users
      class GetUserService < Base::GraphqlService
        # Looks up a user, not a project or group, so no argument names a container to govern by.
        ungovernable!

        register_version '0.1.0', {
          toolset: :core,
          description: 'Get a single GitLab user. Use me: true to look up the authenticated user, for example ' \
            'to find your own user id before setting assignee_ids or reviewer_ids. Provide exactly one of ' \
            'username, id, or me. Returns the numeric id, username, name, state, and web URL.',
          input_schema: {
            type: 'object',
            required: [],
            properties: {
              username: {
                type: 'string',
                description: 'Username of the user to look up.'
              },
              id: {
                type: 'integer',
                description: 'Numeric ID of the user to look up.'
              },
              me: {
                type: 'boolean',
                description: 'Set to true to look up the authenticated user. Omit username and id when set. ' \
                  'false behaves as if me was omitted.'
              }
            }
          },
          annotations: {
            readOnlyHint: true
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::Users::GetUserTool
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
