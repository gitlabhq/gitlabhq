# frozen_string_literal: true

module Mcp
  module Tools
    module MergeRequests
      class GetMergeRequestNotesTool < Mcp::Tools::GraphqlTool
        include Mcp::Tools::Concerns::ResourceFinder

        def self.build_query
          load_graphql('merge_requests/get_merge_request_notes.query.graphql')
        end

        register_version VERSIONS[:v0_1_0], {
          operation_name: 'project',
          graphql_operation: build_query
        }

        def build_variables
          full_path, iid = resolve_target

          {
            fullPath: full_path,
            iid: iid.to_s,
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

        def resolve_target
          if params[:url].present?
            match = ::MergeRequest.link_reference_pattern.match(params[:url])
            raise ArgumentError, "Invalid merge request URL: #{params[:url]}" unless match

            ["#{match[:namespace]}/#{match[:project]}", match[:merge_request]]
          else
            iid = params[:merge_request_iid]
            project_id = params[:project_id]

            raise ArgumentError, 'Provide either url, or project_id and merge_request_iid' unless iid && project_id

            [find_project(project_id).full_path, iid]
          end
        end

        def process_result(result)
          missing = missing_resource(result)
          return resource_not_found_error(missing) if missing

          processed_result = super
          return processed_result if processed_result[:isError]

          merge_request = processed_result[:structuredContent]['mergeRequest']
          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(merge_request) }]
          ::Mcp::Tools::Response.success(formatted_content, merge_request)
        end

        def missing_resource(result)
          return if result['errors'].present?

          project = result.dig('data', 'project')
          return 'Project' if project.nil?

          'Merge request' if project['mergeRequest'].nil?
        end

        def resource_not_found_error(resource)
          ::Mcp::Tools::Response.error(
            "#{resource} not found: it does not exist or you do not have access to it."
          )
        end
      end
    end
  end
end
