# frozen_string_literal: true

module Mcp
  module Tools
    module Repositories
      # Internal helper for AddCommitService's partial-edit expansion: a full-content,
      # multi-path blob read. Reuses the get_repository_file query rather than duplicating it,
      # but skips GetRepositoryFileTool's line-windowing since old_str matching needs the
      # complete file content.
      class BlobsTool < Mcp::Tools::Base::GraphqlTool
        include Gitlab::Utils::StrongMemoize
        include Mcp::Tools::Concerns::ResourceFinder
        include Mcp::Tools::Concerns::UrlParser

        register_version VERSIONS[:v0_1_0], {
          operation_name: 'project',
          graphql_operation: load_graphql('repositories/get_repository_file.query.graphql')
        }

        def execute
          traversal = requested_paths.select { |path| ::Gitlab::PathTraversal.path_traversal?(path) }
          return traversal_response(traversal) if traversal.any?

          excluded = excluded_paths(resolve_project, requested_paths)
          return excluded_response(excluded) if excluded.any?

          super
        end

        def build_variables
          {
            projectPath: resolve_project.full_path,
            filePaths: params[:paths],
            ref: params[:ref]
          }.compact
        end

        private

        # Ai::FileExclusionService reports any path it cannot normalize as not excluded, so a
        # traversal form would slip past the exclusion match. Reject those first, as
        # GetRepositoryFileTool does, so the gate fails closed.
        def requested_paths
          Array(params[:paths]).map { |path| path.to_s.delete_prefix('/') }
        end
        strong_memoize_attr :requested_paths

        def traversal_response(paths)
          ::Mcp::Tools::Base::Response.error(
            "Path(s) #{paths.join(', ')} must not contain a path traversal sequence."
          )
        end

        def excluded_paths(_project, _paths)
          []
        end

        def excluded_response(paths)
          ::Mcp::Tools::Base::Response.error(
            "File(s) #{paths.join(', ')} excluded from AI context by this project's settings and cannot be read."
          )
        end

        def resolve_project
          if params[:project_id].present?
            find_project!(params[:project_id], ability: :read_code)
          else
            parsed_url = parse_parent_url(params[:url])
            raise ArgumentError, 'URL must identify a project' unless parsed_url[:type] == :project

            find_project!(parsed_url[:path], ability: :read_code)
          end
        end
        strong_memoize_attr :resolve_project
      end
    end
  end
end

Mcp::Tools::Repositories::BlobsTool.prepend_mod
