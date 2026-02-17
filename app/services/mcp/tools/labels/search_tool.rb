# frozen_string_literal: true

module Mcp
  module Tools
    module Labels
      class SearchTool < Mcp::Tools::GraphqlTool
        include Mcp::Tools::Concerns::Constants

        class << self
          def build_query
            <<~GRAPHQL
            query searchLabels($fullPath: ID!, $search: String, $isProject: Boolean = false) {
              group(fullPath: $fullPath) @skip(if: $isProject) {
                id
                labels(
                  searchTerm: $search
                  includeAncestorGroups: true
                  includeDescendantGroups: true
                ) {
                  nodes {
                    ... on Label {
                      id
                      title
                    }
                  }
                }
              }
              project(fullPath: $fullPath) @include(if: $isProject) {
                id
                labels(searchTerm: $search, includeAncestorGroups: true) {
                  nodes {
                    ... on Label {
                      id
                      title
                    }
                  }
                }
              }
            }
            GRAPHQL
          end
        end

        register_version VERSIONS[:v0_1_0], {
          graphql_operation: build_query
        }

        def build_variables
          {
            isProject: params[:is_project],
            fullPath: params[:full_path],
            search: params[:search]
          }.compact
        end

        def operation_name
          params[:is_project] ? 'project' : 'group'
        end

        protected

        def build_variables_0_1_0
          build_variables
        end

        private

        def process_result(result)
          processed_result = super

          return processed_result if processed_result[:isError]

          labels = extract_labels(processed_result[:structuredContent])
          return ::Mcp::Tools::Response.error("Operation returned no data") unless labels

          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(labels) }]
          ::Mcp::Tools::Response.success(formatted_content, labels)
        end

        def extract_labels(structured_content)
          structured_content&.dig('labels', 'nodes')
        end
      end
    end
  end
end
