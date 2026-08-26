# frozen_string_literal: true

module Mcp
  module Tools
    module Repositories
      class AddCommitTool < Mcp::Tools::Base::GraphqlTool
        include Mcp::Tools::Concerns::ResourceFinder
        include Mcp::Tools::Concerns::UrlParser

        register_version VERSIONS[:v0_1_0], {
          operation_name: 'commitCreate',
          graphql_operation: load_graphql('repositories/add_commit.mutation.graphql')
        }

        def build_variables
          {
            input: {
              projectPath: resolve_project.full_path,
              branch: params[:branch],
              startBranch: params[:start_branch],
              message: params[:commit_message],
              actions: params[:actions].map { |action| build_action(action) }
            }.compact
          }
        end

        private

        def resolve_project
          unless params[:project_id].present? ^ params[:url].present?
            raise ArgumentError, 'Provide exactly one of project_id or url'
          end

          if params[:project_id].present?
            find_project!(params[:project_id])
          elsif params[:url].present?
            parsed_url = parse_parent_url(params[:url])
            raise ArgumentError, 'URL must identify a project' unless parsed_url[:type] == :project

            find_project!(parsed_url[:path])
          end
        end

        def build_action(action)
          action = action.to_h.with_indifferent_access

          {
            action: action[:action].upcase,
            filePath: action[:file_path],
            content: action[:content],
            previousPath: action[:previous_path],
            encoding: action[:encoding]&.upcase,
            lastCommitId: action[:last_commit_id],
            executeFilemode: action[:execute_filemode]
          }.compact
        end
      end
    end
  end
end
