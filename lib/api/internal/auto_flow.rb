# frozen_string_literal: true

module API
  # AutoFlow Internal API
  module Internal
    class AutoFlow < ::API::Base
      before do
        authenticate_gitlab_kas_request!
      end

      helpers ::API::Helpers::KasHelpers

      namespace 'internal' do
        namespace 'autoflow' do
          desc 'Retrieve repository information' do
            detail 'Retrieve repository information for the given project'
          end
          params do
            requires :id, type: String, desc: 'ID or full path of the project'
          end
          get '/repository_info', feature_category: :deployment_management, urgency: :low do
            project = find_project(params[:id])

            not_found! unless project

            status 200
            {
              project_id: project.id,
              gitaly_info: gitaly_info(project),
              gitaly_repository: gitaly_repository(project),
              default_branch: project.default_branch_or_main
            }
          end
        end
      end
    end
  end
end
