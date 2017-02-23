module API
  # Deployments RESTfull API endpoints
  class Deployments < Grape::API
    include PaginationParams

    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The project ID'
    end
    resource :projects do
      desc 'Get all deployments of the project' do
        detail 'This feature was introduced in GitLab 8.11.'
        success Entities::Deployment
      end
      params do
        use :pagination
      end
      get ':id/deployments' do
        authorize! :read_deployment, user_project

        present paginate(user_project.deployments), with: Entities::Deployment
      end

      desc 'Gets a specific deployment' do
        detail 'This feature was introduced in GitLab 8.11.'
        success Entities::Deployment
      end
      params do
        requires :deployment_id, type: Integer,  desc: 'The deployment ID'
      end
      get ':id/deployments/:deployment_id' do
        authorize! :read_deployment, user_project

        deployment = user_project.deployments.find(params[:deployment_id])

        present deployment, with: Entities::Deployment
      end
    end
  end
end
