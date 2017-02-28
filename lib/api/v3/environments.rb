module API
  module V3
    class Environments < Grape::API
      include PaginationParams

      before { authenticate! }

      params do
        requires :id, type: String, desc: 'The project ID'
      end
      resource :projects do
        desc 'Deletes an existing environment' do
          detail 'This feature was introduced in GitLab 8.11.'
          success ::API::Entities::Environment
        end
        params do
          requires :environment_id, type: Integer,  desc: 'The environment ID'
        end
        delete ':id/environments/:environment_id' do
          authorize! :update_environment, user_project

          environment = user_project.environments.find(params[:environment_id])

          present environment.destroy, with: ::API::Entities::Environment
        end
      end
    end
  end
end
