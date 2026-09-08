# frozen_string_literal: true

module Mcp
  module Tools
    module Projects
      class ListProjectsTool < Mcp::Tools::Base::GraphqlTool
        include Mcp::Tools::Concerns::ResourceFinder
        include Mcp::Tools::Concerns::CursorPagination

        ARCHIVED_DEFAULT = 'exclude'
        DEFAULT_MIN_ACCESS_LEVEL = 'GUEST'

        register_version VERSIONS[:v0_1_0], {
          graphql_operation: load_graphql('projects/list_projects.query.graphql')
        }

        def build_variables
          archived_state = params[:archived] || ARCHIVED_DEFAULT
          group_path = group_full_path

          {
            search: params[:search],
            namespaceFullPath: use_group_branch? ? nil : group_path,
            groupFullPath: use_group_branch? ? group_path : '',
            visibilityLevel: params[:visibility],
            archived: archived_state.upcase,
            includeArchived: archived_state != 'exclude',
            archivedOnly: archived_state == 'only',
            minAccessLevel: effective_min_access_level,
            useGroupBranch: use_group_branch?,
            first: paginated_first,
            after: params[:after]
          }.compact
        end

        # Query.projects has no subgroup traversal (namespace_path is exact-match
        # only), so group_id alone routes through Group.projects(includeSubgroups:
        # true) instead. That resolver has no access-level or visibility argument,
        # so min_access_level/visibility fall back to the non-recursive Query.projects
        # branch (namespace_path), trading subgroup coverage for those filters.
        def operation_name
          use_group_branch? ? 'group' : 'projects'
        end

        protected

        def build_variables_v0_1_0
          build_variables
        end

        private

        def group_full_path
          return unless params[:group_id].present?

          find_parent_by_id_or_path!(:group, params[:group_id]).full_path
        end

        def use_group_branch?
          params[:group_id].present? && params[:min_access_level].blank? && params[:visibility].blank?
        end

        # Replicates the old "defaults to your own projects" behavior: without
        # group_id, an unset min_access_level floors at guest so a bare call or a
        # search doesn't scan every project on the instance. With group_id, an
        # unset min_access_level leaves the listing unrestricted (matches
        # Group.projects, which has no access-level concept at all).
        def effective_min_access_level
          return params[:min_access_level].upcase if params[:min_access_level].present?
          return DEFAULT_MIN_ACCESS_LEVEL if params[:group_id].blank?

          nil
        end

        def process_result(result)
          processed_result = super
          return processed_result if processed_result[:isError]

          projects = extract_projects(processed_result[:structuredContent])
          return ::Mcp::Tools::Base::Response.error('Operation returned no data') unless projects

          projects = projects.merge('subgroupsIncluded' => use_group_branch?) if params[:group_id].present?

          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(projects) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, projects)
        end

        def extract_projects(structured_content)
          return structured_content if operation_name == 'projects'

          structured_content&.dig('projects')
        end
      end
    end
  end
end
