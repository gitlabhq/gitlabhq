# frozen_string_literal: true

module Mcp
  module Tools
    module Groups
      class ListGroupsService < Base::GraphqlService
        register_version '0.1.0', {
          toolset: :core,
          description: 'List GitLab groups. Without group_id, lists top-level groups where you ' \
            'are a member. With group_id, lists the direct subgroups of that group, regardless ' \
            'of membership. Set include_subgroups to true to recurse into all descendant ' \
            'subgroups (with no group_id, this lists your groups at any depth). Archived ' \
            'groups and groups pending deletion are excluded. Useful for discovering group ' \
            'IDs and full paths for other tools.',
          input_schema: {
            type: 'object',
            required: [],
            properties: {
              group_id: {
                type: 'string',
                description: 'ID or full path of a parent group to list subgroups of. ' \
                  'Omit to list top-level groups where you are a member.'
              },
              search: {
                type: 'string',
                description: 'Search groups by name or full path.'
              },
              visibility: {
                type: 'string',
                description: 'Filter by visibility level.',
                enum: ::Gitlab::VisibilityLevel.string_options.keys
              },
              include_subgroups: {
                type: 'boolean',
                description: 'Include all descendant subgroups recursively instead of direct ' \
                  'children only.'
              },
              **Mcp::Tools::Concerns::CursorPagination.input_schema_params(items: 'groups')
            }
          },
          annotations: {
            readOnlyHint: true
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::Groups::ListGroupsTool
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
