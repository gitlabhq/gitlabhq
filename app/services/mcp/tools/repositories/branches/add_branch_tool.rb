# frozen_string_literal: true

module Mcp
  module Tools
    module Repositories
      module Branches
        class AddBranchTool < Mcp::Tools::Base::GraphqlTool
          include Mcp::Tools::Concerns::ResourceFinder
          include Mcp::Tools::Concerns::UrlParser

          register_version VERSIONS[:v0_1_0], {
            operation_name: 'createBranch',
            graphql_operation: load_graphql('repositories/branches/create.mutation.graphql')
          }

          def build_variables
            project = find_project!(project_identifier)

            {
              input: {
                projectPath: project.full_path,
                name: params[:branch],
                ref: params[:ref]
              }
            }
          end

          private

          def project_identifier
            return project_identifier_from_url if params[:url].present?

            raise ArgumentError, 'Provide either url or project_id' if params[:project_id].blank?

            params[:project_id].to_s
          end

          def project_identifier_from_url
            parsed = parse_parent_url(params[:url])
            raise ArgumentError, "Invalid project URL: #{params[:url]}" unless parsed[:type] == :project

            validate_project_id_consistency!(parsed[:path])

            parsed[:path]
          end

          def validate_project_id_consistency!(url_path)
            project_id = params[:project_id].to_s
            return if project_id.blank? || project_id.exclude?('/')
            return if project_id == url_path

            raise ArgumentError, "Project mismatch: project_id is '#{project_id}' but url contains '#{url_path}'"
          end
        end
      end
    end
  end
end

Mcp::Tools::Repositories::Branches::AddBranchTool.prepend_mod
