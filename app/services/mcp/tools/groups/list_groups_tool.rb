# frozen_string_literal: true

module Mcp
  module Tools
    module Groups
      class ListGroupsTool < Mcp::Tools::Base::GraphqlTool
        include Mcp::Tools::Concerns::ResourceFinder
        include Mcp::Tools::Concerns::CursorPagination

        register_version VERSIONS[:v0_1_0], {
          graphql_operation: load_graphql('groups/list_groups.query.graphql'),
          operation_name: 'groups'
        }

        def build_variables
          parent_path = parent_full_path

          {
            search: params[:search],
            parentPath: parent_path,
            includeSubgroups: params[:include_subgroups],
            # Without a parent, a plain call lists top-level groups only;
            # include_subgroups widens it to the user's groups at any depth.
            topLevelOnly: parent_path.nil? && !params[:include_subgroups],
            # Instance-wide listing stays membership-scoped: allAvailable unions in
            # every public group (times out on GitLab.com). A parent-scoped listing
            # is bounded, and allAvailable keeps public subgroups visible there.
            allAvailable: parent_path.present?,
            visibilityLevel: params[:visibility],
            first: paginated_first,
            after: params[:after]
          }.compact
        end

        protected

        def build_variables_v0_1_0
          build_variables
        end

        private

        def parent_full_path
          return unless params[:group_id].present?

          find_parent_by_id_or_path!(:group, params[:group_id]).full_path
        end

        # Unwrap GIDs to numeric IDs so the output chains directly back into
        # group_id, matching the get_project/list_project_members convention.
        def process_result(result)
          processed_result = super
          return processed_result if processed_result[:isError]

          groups = processed_result[:structuredContent]
          groups['nodes']&.each do |node|
            node['id'] = ::GlobalID.parse(node['id']).model_id.to_i
            node['parent']['id'] = ::GlobalID.parse(node['parent']['id']).model_id.to_i if node['parent']
          end

          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(groups) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, groups)
        end
      end
    end
  end
end
