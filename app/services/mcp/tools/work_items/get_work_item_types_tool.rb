# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class GetWorkItemTypesTool < BaseTool
        class << self
          def build_query
            <<~GRAPHQL
              query GetNamespaceWorkItemTypes($fullPath: ID!) {
                namespace(fullPath: $fullPath) {
                  id
                  workItemTypes {
                    nodes {
                      id
                      name
                      iconName
                      widgetDefinitions {
                        type
                      }
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

          { fullPath: parent_info[:full_path] }
        end

        protected

        def build_variables_0_1_0
          build_variables
        end

        private

        def process_result(result)
          processed = super
          return processed if processed[:isError]

          types = extract_work_item_types(processed[:structuredContent])
          return ::Mcp::Tools::Response.error("Work item types not found or inaccessible") if types.nil?

          payload = { 'workItemTypes' => types }
          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(payload) }]
          ::Mcp::Tools::Response.success(formatted_content, payload)
        end

        def extract_work_item_types(structured_content)
          structured_content.dig('workItemTypes', 'nodes')
        end
      end
    end
  end
end
