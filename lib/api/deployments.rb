module API
  # Deployments RESTful API endpoints
  class Deployments < Grape::API
    include PaginationParams

    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The project ID'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc 'Get all deployments of the project' do
        detail 'This feature was introduced in GitLab 8.11.'
        success Entities::Deployment
      end
      params do
        use :pagination
        optional :order_by, type: String, values: %w[id iid created_at ref], default: 'id', desc: 'Return deployments ordered by `id` or `iid` or `created_at` or `ref`'
        optional :sort, type: String, values: %w[asc desc], default: 'asc', desc: 'Sort by asc (ascending) or desc (descending)'
      end
      get ':id/deployments' do
        authorize! :read_deployment, user_project

        present paginate(user_project.deployments.order(params[:order_by] => params[:sort])), with: Entities::Deployment
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
