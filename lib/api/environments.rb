module API
  # Environments RESTfull API endpoints
  class Environments < Grape::API
    before { authenticate! }

    resource :projects do
      # Get all labels of the project
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   GET /projects/:id/environments
      get ':id/environments' do
        authorize! :read_environment, user_project

        present paginate(user_project.environments), with: Entities::Environment
      end

      # Creates a new environment
      #
      # Parameters:
      #   id    (required)        - The ID of a project
      #   name  (required)        - The name of the environment to be created
      #   external_url (optional) - URL on which this deployment is viewable
      #
      # Example Request:
      #   POST /projects/:id/labels
      post ':id/environments' do
        authorize! :create_environment, user_project
        required_attributes! [:name]

        attrs = attributes_for_keys [:name, :external_url]
        environment = user_project.environments.find_by(name: attrs[:name])

        conflict!('Environment already exists') if environment

        environment = user_project.environments.create(attrs)

        if environment.valid?
          present environment, with: Entities::Environment
        else
          render_validation_error!(environment)
        end
      end

      # Deletes an existing environment
      #
      # Parameters:
      #   id    (required)          - The ID of a project
      #   environment_id (required) - The name of the environment to be deleted
      #
      # Example Request:
      #   DELETE /projects/:id/environments/:environment_id
      delete ':id/environments/:environment_id' do
        authorize! :admin_environment, user_project

        environment = user_project.environments.find(params[:environment_id])

        present environment.destroy, with: Entities::Environment
      end

      # Updates an existing environment
      #
      # Parameters:
      #   id              (required) - The ID of a project
      #   environment_id  (required) - The ID of the environment
      #   name            (optional) - The name of the label to be deleted
      #   external_url    (optional) - The new name of the label
      #
      # Example Request:
      #   PUT /projects/:id/environments/:environment_id
      put ':id/environments/:environment_id' do
        authorize! :update_environment, user_project

        environment = user_project.environments.find(params[:environment_id])

        attrs = attributes_for_keys [:name, :external_url]

        if environment.update(attrs)
          present environment, with: Entities::Environment
        else
          render_validation_error!(environment)
        end
      end
    end
  end
end
