# frozen_string_literal: true

module Mcp
  module Tools
    module MergeRequests
      class GetMergeRequestTool < Mcp::Tools::Base::GraphqlTool
        include Mcp::Tools::Concerns::ResourceFinder

        def self.build_query
          load_graphql('merge_requests/get_merge_request.query.graphql')
        end

        register_version VERSIONS[:v0_1_0], {
          operation_name: 'project',
          graphql_operation: build_query
        }

        def build_variables
          full_path, iid = resolve_target
          facets = Array(params[:include]).map(&:to_s)
          detail = params[:detail].to_s
          diffs_requested = facets.include?('diffs')

          {
            fullPath: full_path,
            iid: iid.to_s,
            includeDiffs: diffs_requested,
            includeDiffFiles: diffs_requested && detail != 'none',
            includeDiffPatches: diffs_requested && detail == 'full_patch',
            includeCommits: facets.include?('commits'),
            includeNotes: facets.include?('notes'),
            includePipelines: facets.include?('pipelines'),
            includeDiscussions: facets.include?('discussions'),
            includeApprovals: facets.include?('approvals'),
            notesAfter: params[:notes_after],
            notesFirst: params[:notes_first],
            diffsAfter: params[:diffs_after],
            diffsFirst: params[:diffs_first]
          }.compact
        end

        protected

        def build_variables_v0_1_0
          build_variables
        end

        private

        def resolve_target
          @resolve_target ||=
            if params[:url].present?
              match = ::MergeRequest.link_reference_pattern.match(params[:url])
              raise ArgumentError, "Invalid merge request URL: #{params[:url]}" unless match

              ["#{match[:namespace]}/#{match[:project]}", match[:merge_request]]
            else
              iid = params[:merge_request_iid]
              project_id = params[:project_id]

              raise ArgumentError, 'Provide either url, or project_id and merge_request_iid' unless iid && project_id

              [find_project!(project_id).full_path, iid]
            end
        end

        def process_result(result)
          missing = missing_resource(result)
          return resource_not_found_error(missing) if missing

          processed_result = super
          return processed_result if processed_result[:isError]

          merge_request = processed_result[:structuredContent]['mergeRequest']
          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(merge_request) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, merge_request)
        end

        def missing_resource(result)
          return if result['errors'].present?

          project = result.dig('data', 'project')
          return 'Project' if project.nil?

          'Merge request' if project['mergeRequest'].nil?
        end

        def resource_not_found_error(resource)
          ::Mcp::Tools::Base::Response.error(
            "#{resource} not found or inaccessible"
          )
        end
      end
    end
  end
end

Mcp::Tools::MergeRequests::GetMergeRequestTool.prepend_mod
