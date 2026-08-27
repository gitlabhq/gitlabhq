# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class GetWorkItemTool < BaseTool
        register_version VERSIONS[:v0_1_0], {
          operation_name: 'workItem',
          graphql_operation: load_graphql('work_items/get_work_item.query.graphql')
        }

        def build_variables
          facets = Array(params[:include]).map(&:to_s)

          {
            id: resolve_work_item_id,
            includeNotes: facets.include?('notes'),
            includeRelatedMergeRequests: facets.include?('related_merge_requests'),
            # The canonical params win over the deprecated aliases kept for
            # callers of the replaced DAP tool.
            relatedMergeRequestsFirst: params[:related_merge_requests_first] ||
              params[:mr_page_size] || Mcp::Tools::Concerns::CursorPagination::DEFAULT_PAGE_SIZE,
            relatedMergeRequestsAfter: params[:related_merge_requests_after] || params[:mr_pagination_cursor]
          }.compact
        end

        protected

        def build_variables_v0_1_0
          build_variables
        end

        private

        def process_result(result)
          return resource_not_found_error if resource_not_found?(result)

          super
        end

        def resource_not_found_error
          ::Mcp::Tools::Base::Response.error(
            'Work item not found or inaccessible.'
          )
        end
      end
    end
  end
end
