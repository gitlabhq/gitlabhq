# frozen_string_literal: true

module Mcp
  module Tools
    module Commits
      class ListCommitsTool < Mcp::Tools::Base::GraphqlTool
        include Mcp::Tools::Concerns::ResourceFinder
        include Mcp::Tools::Concerns::UrlParser

        PARENT_PARAMS = %i[url project_id].freeze

        def self.stats_max_first
          @stats_max_first ||= ::Types::Repositories::CommitType
            .fields['diffStatsSummary']
            .extensions
            .find { |ext| ext.is_a?(::Gitlab::Graphql::Limit::FieldCallCount) }
            .options[:limit]
        end

        register_version VERSIONS[:v0_1_0], {
          graphql_operation: load_graphql('commits/list_commits.query.graphql'),
          operation_name: 'project'
        }

        def build_variables
          project = resolve_project
          with_stats = params[:with_stats] || false
          ref = params[:ref_name].presence || project.default_branch
          raise ArgumentError, 'Project has no default branch; provide ref_name.' if ref.blank?

          {
            fullPath: project.full_path,
            ref: ref,
            path: params[:path],
            author: params[:author],
            committedAfter: params[:since],
            committedBefore: params[:until],
            firstParent: params[:first_parent],
            order: params[:order]&.upcase,
            withStats: with_stats,
            first: resolve_first(with_stats),
            after: params[:after]
          }.compact
        end

        protected

        def build_variables_v0_1_0
          build_variables
        end

        private

        def resolve_first(with_stats)
          return params[:first] || 20 unless with_stats

          cap = self.class.stats_max_first
          first = params[:first] || cap

          if first > cap
            raise ArgumentError,
              "with_stats can be requested for at most #{cap} commits per page; set first to #{cap} or less."
          end

          first
        end

        def resolve_project
          provided = PARENT_PARAMS.select { |key| params[key].present? }

          raise ArgumentError, 'Provide exactly one of: url or project_id' unless provided.one?

          identifier = provided.first == :url ? parse_parent_url(params[:url])[:path] : params[:project_id]

          find_parent_by_id_or_path!(:project, identifier)
        end

        def process_result(result)
          return resource_not_found_error if resource_not_found?(result)

          processed_result = super
          return processed_result if processed_result[:isError]

          commits = processed_result[:structuredContent].dig('repository', 'commits')
          return ::Mcp::Tools::Base::Response.error('Operation returned no data') unless commits

          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(commits) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, commits)
        end

        def resource_not_found_error
          ::Mcp::Tools::Base::Response.error('Project not found or inaccessible')
        end
      end
    end
  end
end
