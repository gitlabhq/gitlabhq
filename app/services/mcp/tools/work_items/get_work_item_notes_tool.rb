# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class GetWorkItemNotesTool < BaseTool
        extend Gitlab::Utils::Override
        include Mcp::Tools::Concerns::CursorPagination

        DEFAULT_NOTES_PAGE_SIZE = 100

        register_version VERSIONS[:v0_1_0], {
          operation_name: 'workItem',
          graphql_operation: load_graphql('work_items/get_work_item_notes.query.graphql')
        }

        def build_variables
          {
            id: resolve_work_item_id,
            **resolve_pagination_direction
          }.compact
        end

        protected

        def build_variables_v0_1_0
          build_variables
        end

        private

        override :default_page_size
        def default_page_size
          DEFAULT_NOTES_PAGE_SIZE
        end

        def process_result(result)
          processed_result = super

          return processed_result if processed_result[:isError]

          notes = extract_notes(processed_result[:structuredContent])
          return ::Mcp::Tools::Base::Response.error("Operation returned no data") unless notes

          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(notes) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, notes)
        end

        def extract_notes(structured_content)
          structured_content&.dig('widgets')&.find { |w| w['notes'] }&.dig('notes')
        end
      end
    end
  end
end
