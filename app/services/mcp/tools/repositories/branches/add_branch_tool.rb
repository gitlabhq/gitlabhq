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
            validate_numeric_project_id_consistency!(project, project_identifier) if params[:url].present?

            {
              input: {
                projectPath: project.full_path,
                name: params[:branch],
                ref: params[:ref]
              }
            }
          end

          private

          def process_result(result)
            processed_result = super
            return processed_result if processed_result[:isError]

            data = processed_result[:structuredContent]
            branch = data['branch']
            return processed_result unless branch

            branch['web_url'] = ::Gitlab::Routing.url_helpers.project_tree_url(project, branch['name'])
            ::Mcp::Tools::Base::Response.success([{ type: 'text', text: Gitlab::Json.dump(data) }], data)
          end

          def project
            @project ||= find_project!(project_identifier)
          end

          def project_identifier
            @project_identifier ||=
              if params[:url].present?
                project_identifier_from_url
              elsif params[:project_id].present?
                params[:project_id].to_s
              else
                raise ArgumentError, 'Provide either url or project_id'
              end
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

          def validate_numeric_project_id_consistency!(url_project, url_path)
            project_id = params[:project_id].to_s
            return unless Gitlab::ResourceLookup::INTEGER_ID_REGEX.match?(project_id)
            return if url_project.id == project_id.to_i

            raise ArgumentError, "Project mismatch: project_id is '#{project_id}' but url contains '#{url_path}'"
          end
        end
      end
    end
  end
end

Mcp::Tools::Repositories::Branches::AddBranchTool.prepend_mod
