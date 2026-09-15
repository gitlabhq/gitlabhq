# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class GetWorkItemTool < BaseTool
        DEFAULT_NOTES_PAGE_SIZE = 100

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
            **notes_pagination_variables(facets),
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

        # A GraphQL connection rejects mixed directions, so fail fast with an
        # actionable message instead of surfacing the raw connection error.
        # Skipped entirely without the notes facet: agents reuse arguments
        # across calls, and stray pagination params must not fail other reads.
        def notes_pagination_variables(facets)
          return {} unless facets.include?('notes')

          backward = params[:notes_last].present? || params[:notes_before].present?
          forward = params[:notes_first].present? || params[:notes_after].present?

          if backward && forward
            raise ArgumentError, 'Provide notes_first/notes_after or notes_last/notes_before, not both directions'
          end

          if backward
            { notesLast: params[:notes_last] || DEFAULT_NOTES_PAGE_SIZE, notesBefore: params[:notes_before] }
          else
            { notesFirst: params[:notes_first] || DEFAULT_NOTES_PAGE_SIZE, notesAfter: params[:notes_after] }
          end
        end

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
