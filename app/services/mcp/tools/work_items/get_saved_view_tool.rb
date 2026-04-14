# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class GetSavedViewTool < BaseTool
        class << self
          def build_query
            <<~GRAPHQL
              query GetNamespaceSavedView($fullPath: ID!, $id: WorkItemsSavedViewsSavedViewID!) {
                namespace(fullPath: $fullPath) {
                  id
                  savedViews(id: $id) {
                    nodes {
                      id
                      name
                      description
                      filters
                      sort
                    }
                  }
                }
              }
            GRAPHQL
          end
        end

        register_version VERSIONS[:v0_1_0], {
          operation_name: 'namespace',
          graphql_operation: build_query
        }

        def build_variables
          parent_info = resolve_parent

          {
            fullPath: parent_info[:full_path],
            id: params[:saved_view_id]
          }.compact
        end

        protected

        def build_variables_0_1_0
          build_variables
        end

        private

        def process_result(result)
          processed = super
          return processed if processed[:isError]

          saved_view = extract_saved_view(processed[:structuredContent])
          return ::Mcp::Tools::Response.error("Saved view not found or inaccessible") unless saved_view

          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(saved_view) }]
          ::Mcp::Tools::Response.success(formatted_content, saved_view)
        end

        def extract_saved_view(structured_content)
          structured_content.dig('savedViews', 'nodes')&.first
        end
      end
    end
  end
end
