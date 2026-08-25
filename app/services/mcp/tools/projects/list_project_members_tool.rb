# frozen_string_literal: true

module Mcp
  module Tools
    module Projects
      class ListProjectMembersTool < Mcp::Tools::Base::GraphqlTool
        include Mcp::Tools::Concerns::ResourceFinder

        DEFAULT_PAGE_SIZE = 20
        MAX_PAGE_SIZE = 100
        DIRECT_RELATIONS = %w[DIRECT].freeze
        INHERITED_RELATIONS = %w[DIRECT INHERITED DESCENDANTS].freeze

        register_version VERSIONS[:v0_1_0], {
          graphql_operation: load_graphql('projects/list_project_members.query.graphql'),
          operation_name: 'project'
        }

        def build_variables
          {
            fullPath: find_project!(params[:project_id]).full_path,
            search: params[:query],
            relations: relations,
            first: params[:first] || DEFAULT_PAGE_SIZE,
            after: params[:after]
          }.compact
        end

        protected

        def build_variables_v0_1_0
          build_variables
        end

        private

        def relations
          params[:include_inherited] ? INHERITED_RELATIONS : DIRECT_RELATIONS
        end

        def process_result(result)
          return resource_not_found_error if resource_not_found?(result)
          return members_forbidden_error if members_forbidden?(result)

          processed_result = super
          return processed_result if processed_result[:isError]

          connection = processed_result[:structuredContent]['projectMembers']
          data = {
            items: members(connection['nodes']),
            metadata: {
              has_next_page: connection.dig('pageInfo', 'hasNextPage'),
              end_cursor: connection.dig('pageInfo', 'endCursor')
            }
          }

          ::Mcp::Tools::Base::Response.success([{ type: 'text', text: Gitlab::Json.dump(data) }], data)
        end

        # Members invited by email have no user until the invitation is accepted, and every field
        # this tool reports comes from that user, so they are skipped rather than returned empty.
        def members(nodes)
          nodes.filter_map do |node|
            user = node['user']
            next unless user

            {
              id: ::GlobalID.parse(user['id']).model_id.to_i,
              username: user['username'],
              name: user['name'],
              access_level: node.dig('accessLevel', 'integerValue'),
              access_level_name: node.dig('accessLevel', 'humanAccess'),
              expires_at: node['expiresAt']
            }
          end
        end

        # A resolved project with a null `projectMembers` means `:read_project_member` was denied.
        def members_forbidden?(result)
          project = result.dig('data', 'project')

          project.present? && project.key?('projectMembers') && project['projectMembers'].nil?
        end

        def resource_not_found_error
          ::Mcp::Tools::Base::Response.error(
            'Project not found or inaccessible'
          )
        end

        def members_forbidden_error
          ::Mcp::Tools::Base::Response.error(
            'Access denied: you do not have permission to list the members of this project.'
          )
        end
      end
    end
  end
end
