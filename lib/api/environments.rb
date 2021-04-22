# frozen_string_literal: true

module API
  # Environments RESTfull API endpoints
  class Environments < ::API::Base
    include PaginationParams

    before { authenticate! }

    feature_category :continuous_delivery

    params do
      requires :id, type: String, desc: 'The project ID'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get all environments of the project' do
        detail 'This feature was introduced in GitLab 8.11.'
        success Entities::Environment
      end
      params do
        use :pagination
        optional :name, type: String, desc: 'Returns the environment with this name'
        optional :search, type: String, desc: 'Returns list of environments matching the search criteria'
        mutually_exclusive :name, :search, message: 'cannot be used together'
      end
      get ':id/environments' do
        authorize! :read_environment, user_project

        environments = ::Environments::EnvironmentsFinder.new(user_project, current_user, params).execute

        present paginate(environments), with: Entities::Environment, current_user: current_user
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
          present environment, with: Entities::Environment, current_user: current_user
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
          present environment, with: Entities::Environment, current_user: current_user
        else
          render_validation_error!(environment)
        end
      end

      desc "Delete multiple stopped review apps" do
        detail "Remove multiple stopped review environments older than a specific age"
        success Entities::Environment
      end
      params do
        optional :before, type: Time, desc: "The timestamp before which environments can be deleted. Defaults to 30 days ago.", default: -> { 30.days.ago }
        optional :limit, type: Integer, desc: "Maximum number of environments to delete. Defaults to 100.", default: 100, values: 1..1000
        optional :dry_run, type: Boolean, desc: "If set, perform a dry run where no actual deletions will be performed. Defaults to true.", default: true
      end
      delete ":id/environments/review_apps" do
        authorize! :read_environment, user_project

        result = ::Environments::ScheduleToDeleteReviewAppsService.new(user_project, current_user, params).execute

        response = {
          scheduled_entries: Entities::Environment.represent(result.scheduled_entries),
          unprocessable_entries: Entities::Environment.represent(result.unprocessable_entries)
        }

        if result.success?
          status result.status
          present response, current_user: current_user
        else
          render_api_error!(response.merge!(message: result.error_message), result.status)
        end
      end

      desc 'Deletes an existing environment' do
        detail 'This feature was introduced in GitLab 8.11.'
        success Entities::Environment
      end
      params do
        requires :environment_id, type: Integer, desc: 'The environment ID'
      end
      delete ':id/environments/:environment_id' do
        authorize! :read_environment, user_project

        environment = user_project.environments.find(params[:environment_id])
        authorize! :destroy_environment, environment

        destroy_conditionally!(environment)
      end

      desc 'Stops an existing environment' do
        success Entities::Environment
      end
      params do
        requires :environment_id, type: Integer, desc: 'The environment ID'
      end
      post ':id/environments/:environment_id/stop' do
        authorize! :read_environment, user_project

        environment = user_project.environments.find(params[:environment_id])
        authorize! :stop_environment, environment

        environment.stop_with_action!(current_user)

        status 200
        present environment, with: Entities::Environment, current_user: current_user
      end

      desc 'Get a single environment' do
        success Entities::Environment
      end
      params do
        requires :environment_id, type: Integer, desc: 'The environment ID'
      end
      get ':id/environments/:environment_id' do
        authorize! :read_environment, user_project

        environment = user_project.environments.find(params[:environment_id])
        present environment, with: Entities::Environment, current_user: current_user,
                             except: [:project, { last_deployment: [:environment] }],
                             last_deployment: true
      end
    end
  end
end
