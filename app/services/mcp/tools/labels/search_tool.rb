# frozen_string_literal: true

module Mcp
  module Tools
    module Labels
      class SearchTool < Mcp::Tools::Base::GraphqlTool
        register_version VERSIONS[:v0_1_0], {
          graphql_operation: load_graphql('labels/search.v0_1_0.query.graphql')
        }

        register_version '0.2.0', {
          graphql_operation: load_graphql('labels/search.v0_2_0.query.graphql')
        }

        def execute
          return super if version == VERSIONS[:v0_1_0] || !params[:search].is_a?(Array)

          labels = []
          result = nil

          Array(params[:search]).uniq.each do |term|
            result = self.class.new(
              current_user: current_user,
              params: params.merge(search: term),
              version: version
            ).execute

            break if result[:isError]

            labels.concat(result[:structuredContent][:items])
          end

          return result if result[:isError]

          labels.uniq! { |label| label['id'] }

          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(labels) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, labels)
        end

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

        def build_variables_v0_1_0
          build_variables
        end

        private

        def process_result(result)
          processed_result = super

          return processed_result if processed_result[:isError]

          labels = extract_labels(processed_result[:structuredContent])
          return ::Mcp::Tools::Base::Response.error("Operation returned no data") unless labels

          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(labels) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, labels)
        end

        def extract_labels(structured_content)
          structured_content&.dig('labels', 'nodes')
        end

        def resource_not_found_error
          resource_type = params[:is_project] ? 'Project' : 'Group'
          message = "#{resource_type} '#{params[:full_path]}' not found or inaccessible"
          ::Mcp::Tools::Base::Response.error(message, reason: ::Mcp::Tools::Base::Response::Reason::NOT_FOUND)
        end
      end
    end
  end
end
