# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class GetWorkItemNotesTool < BaseTool
        register_version VERSIONS[:v0_1_0], {
          operation_name: 'workItem',
          graphql_operation: load_graphql('work_items/get_work_item_notes.query.graphql')
        }

        def build_variables
          work_item_id = resolve_work_item_id

          {
            id: work_item_id,
            after: params[:after],
            before: params[:before],
            first: params[:first],
            last: params[:last]
          }.compact
        end

        protected

        def build_variables_0_1_0
          build_variables
        end

        private

        def process_result(result)
          processed_result = super

          return processed_result if processed_result[:isError]

          notes = extract_notes(processed_result[:structuredContent])
          return ::Mcp::Tools::Response.error("Operation returned no data") unless notes

          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(notes) }]
          ::Mcp::Tools::Response.success(formatted_content, notes)
        end

        def extract_notes(structured_content)
          structured_content&.dig('widgets')&.find { |w| w['notes'] }&.dig('notes')
        end
      end
    end
  end
end
