# frozen_string_literal: true

module Mcp
  module Tools
    module Labels
      class SearchTool < Mcp::Tools::GraphqlTool
        register_version VERSIONS[:v0_1_0], {
          graphql_operation: load_graphql('labels/search.query.graphql')
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
          return resource_not_found_error if resource_not_found?(result)

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

        def resource_not_found?(result)
          result['errors'].blank? && result.dig('data', operation_name).nil?
        end

        def resource_not_found_error
          resource_type = params[:is_project] ? 'Project' : 'Group'
          message = "#{resource_type} not found: the provided #{resource_type.downcase} path " \
            "\"#{params[:full_path]}\" does not exist or you do not have access to it."
          ::Mcp::Tools::Response.error(message)
        end
      end
    end
  end
end
