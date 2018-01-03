module API
  # Environments RESTfull API endpoints
  class Environments < Grape::API
    include ::API::Helpers::CustomValidators
    include PaginationParams

    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The project ID'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc 'Get all environments of the project' do
        detail 'This feature was introduced in GitLab 8.11.'
        success Entities::Environment
      end
      params do
        use :pagination
      end
      get ':id/environments' do
        authorize! :read_environment, user_project

        present paginate(user_project.environments), with: Entities::Environment
      end

      desc 'Creates a new environment' do
        detail 'This feature was introduced in GitLab 8.11.'
        success Entities::Environment
      end
      params do
        requires :name,           type: String,   desc: 'The name of the environment to be created'
        optional :external_url,   type: String,   desc: 'URL on which this deployment is viewable'
        optional :slug, absence: { message: "is automatically generated and cannot be changed" }
      end
      post ':id/environments' do
        authorize! :create_environment, user_project

        environment = user_project.environments.create(declared_params)

        if environment.persisted?
          present environment, with: Entities::Environment
        else
          render_validation_error!(environment)
        end
      end

      desc 'Updates an existing environment' do
        detail 'This feature was introduced in GitLab 8.11.'
        success Entities::Environment
      end
      params do
        requires :environment_id, type: Integer,  desc: 'The environment ID'
        optional :name,           type: String,   desc: 'The new environment name'
        optional :external_url,   type: String,   desc: 'The new URL on which this deployment is viewable'
        optional :slug, absence: { message: "is automatically generated and cannot be changed" }
      end
      put ':id/environments/:environment_id' do
        authorize! :update_environment, user_project

        environment = user_project.environments.find(params[:environment_id])

        update_params = declared_params(include_missing: false).extract!(:name, :external_url)
        if environment.update(update_params)
          present environment, with: Entities::Environment
        else
          render_validation_error!(environment)
        end
      end

      desc 'Deletes an existing environment' do
        detail 'This feature was introduced in GitLab 8.11.'
        success Entities::Environment
      end
      params do
        requires :environment_id, type: Integer,  desc: 'The environment ID'
      end
      delete ':id/environments/:environment_id' do
        authorize! :update_environment, user_project

        environment = user_project.environments.find(params[:environment_id])

        destroy_conditionally!(environment)
      end

      desc 'Stops an existing environment' do
        success Entities::Environment
      end
      params do
        requires :environment_id, type: Integer,  desc: 'The environment ID'
      end
      post ':id/environments/:environment_id/stop' do
        authorize! :create_deployment, user_project

        environment = user_project.environments.find(params[:environment_id])

        environment.stop_with_action!(current_user)

        status 200
        present environment, with: Entities::Environment
      end
    end
  end
end
