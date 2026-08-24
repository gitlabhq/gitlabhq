# frozen_string_literal: true

module Mcp
  module Tools
    module Commits
      class GetCommitTool < Mcp::Tools::Base::GraphqlTool
        include Mcp::Tools::Concerns::ResourceFinder

        DEFAULT_DETAIL = 'stats'

        register_version VERSIONS[:v0_1_0], {
          operation_name: 'project',
          graphql_operation: load_graphql('commits/get_commit.query.graphql')
        }

        def build_variables
          full_path, ref = resolve_target
          facets = Array(params[:include]).map(&:to_s)
          diff_detail = params[:diff_detail] || DEFAULT_DETAIL
          with_diff = facets.include?('diff')

          {
            fullPath: full_path,
            ref: ref,
            withStats: with_diff && diff_detail == 'stats',
            withPatch: with_diff && diff_detail == 'full_patch',
            withNotes: facets.include?('notes'),
            notesAfter: params[:notes_after],
            notesFirst: params[:notes_first]
          }.compact
        end

        protected

        def build_variables_v0_1_0
          build_variables
        end

        private

        def resolve_target
          if params[:url].present?
            if params[:project_id].present? || params[:commit_sha].present?
              raise ArgumentError, 'Provide either url, or project_id and commit_sha, not both'
            end

            match = ::Commit.link_reference_pattern.match(params[:url])
            raise ArgumentError, "Invalid commit URL: #{params[:url]}" unless match && match[:commit].present?

            ["#{match[:namespace]}/#{match[:project]}", match[:commit]]
          else
            sha = params[:commit_sha]
            project_id = params[:project_id]

            raise ArgumentError, 'Provide either url, or project_id and commit_sha' unless sha && project_id

            [find_project!(project_id).full_path, sha]
          end
        end

        def process_result(result)
          missing = missing_resource(result)
          return resource_not_found_error(missing) if missing

          processed_result = super
          return processed_result if processed_result[:isError]

          commit = processed_result[:structuredContent].dig('repository', 'commit')
          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(commit) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, commit)
        end

        def missing_resource(result)
          return if result['errors'].present?

          project = result.dig('data', 'project')
          return 'Project' if project.nil?

          'Commit' if project.dig('repository', 'commit').nil?
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
