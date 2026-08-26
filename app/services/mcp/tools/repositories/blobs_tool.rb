# frozen_string_literal: true

module Mcp
  module Tools
    module Repositories
      # Internal helper for AddCommitService's partial-edit expansion: a full-content,
      # multi-path blob read. Reuses the get_repository_file query rather than duplicating it,
      # but skips GetRepositoryFileTool's line-windowing since old_str matching needs the
      # complete file content.
      class BlobsTool < Mcp::Tools::Base::GraphqlTool
        include Mcp::Tools::Concerns::ResourceFinder
        include Mcp::Tools::Concerns::UrlParser

        register_version VERSIONS[:v0_1_0], {
          operation_name: 'project',
          graphql_operation: load_graphql('repositories/get_repository_file.query.graphql')
        }

        def build_variables
          {
            projectPath: resolve_project.full_path,
            filePaths: params[:paths],
            ref: params[:ref]
          }.compact
        end

        private

        def resolve_project
          if params[:project_id].present?
            find_project!(params[:project_id])
          else
            parsed_url = parse_parent_url(params[:url])
            raise ArgumentError, 'URL must identify a project' unless parsed_url[:type] == :project

            find_project!(parsed_url[:path])
          end
        end
      end
    end
  end
end
