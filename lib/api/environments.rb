# frozen_string_literal: true

module API
  # Environments RESTfull API endpoints
  class Environments < ::API::Base
    include PaginationParams

    environments_tags = %w[environments]

    before { authenticate! }

    feature_category :continuous_delivery
    urgency :low

    MIN_SEARCH_LENGTH = 3
    # rubocop:disable Gitlab/DocUrl
    ENVIRONMENT_NAME_UPDATE_ERROR = <<~DESC
      Updating environment name was deprecated in GitLab 15.9 and to be removed in GitLab 16.0.
      For workaround, see [the documentation](https://docs.gitlab.com/ee/ci/environments/#rename-an-environment).
      For more information, see [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/338897)
    DESC
    # rubocop:enable Gitlab/DocUrl

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project owned by the authenticated user'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'List environments' do
        detail 'Get all environments for a given project. This feature was introduced in GitLab 8.11.'
        success Entities::Environment
        is_array true
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags environments_tags
      end
      params do
        use :pagination
        optional :name, type: String, desc: 'Return the environment with this name. Mutually exclusive with search'
        optional :search, type: String, desc: "Return list of environments matching the search criteria. Mutually exclusive with name. Must be at least #{MIN_SEARCH_LENGTH} characters."
        optional :states,
          type: String,
          values: Environment.valid_states.map(&:to_s),
          desc: 'List all environments that match a specific state. Accepted values: `available`, `stopping`, or `stopped`. If no state value given, returns all environments'
        mutually_exclusive :name, :search, message: 'cannot be used together'
      end
      get ':id/environments' do
        authorize! :read_environment, user_project

        if Feature.enabled?(:environment_search_api_min_chars, user_project) && params[:search].present? && params[:search].length < MIN_SEARCH_LENGTH
          bad_request!("Search query is less than #{MIN_SEARCH_LENGTH} characters")
        end

        environments = ::Environments::EnvironmentsFinder.new(user_project, current_user, declared_params(include_missing: false)).execute

        present paginate(environments), with: Entities::Environment, current_user: current_user
      end

      desc 'Create a new environment' do
        detail 'Creates a new environment with the given name and `external_url`. It returns `201` if the environment was successfully created, `400` for wrong parameters. This feature was introduced in GitLab 8.11.'
        success Entities::Environment
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags environments_tags
      end
      params do
        requires :name,           type: String,   desc: 'The name of the environment'
        optional :external_url,   type: String,   desc: 'Place to link to for this environment'
        optional :slug, absence: { message: "is automatically generated and cannot be changed" }, documentation: { hidden: true }
        optional :tier, type: String, values: Environment.tiers.keys, desc: 'The tier of the new environment. Allowed values are `production`, `staging`, `testing`, `development`, and `other`'
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

      desc 'Update an existing environment' do
        detail 'Updates an existing environment name and/or `external_url`. It returns `200` if the environment was successfully updated. In case of an error, a status code `400` is returned. This feature was introduced in GitLab 8.11.'
        success Entities::Environment
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags environments_tags
      end
      params do
        requires :environment_id, type: Integer,  desc: 'The ID of the environment'
        optional :external_url,   type: String,   desc: 'The new URL on which this deployment is viewable'
        optional :slug, absence: { message: "is automatically generated and cannot be changed" }, documentation: { hidden: true }
        optional :tier, type: String, values: Environment.tiers.keys, desc: 'The tier of the new environment. Allowed values are `production`, `staging`, `testing`, `development`, and `other`'
      end
      put ':id/environments/:environment_id' do
        authorize! :update_environment, user_project

        environment = user_project.environments.find(params[:environment_id])

        update_params = declared_params(include_missing: false).extract!(:external_url, :tier)

        # For the transition period, we implicitly extract `:name` field.
        # This line should be removed when disallow_environment_name_update feature flag is removed.
        update_params[:name] = params[:name] if params[:name].present?

        environment.assign_attributes(update_params)

        if environment.name_changed? && ::Feature.enabled?(:disallow_environment_name_update, user_project)
          render_api_error!(ENVIRONMENT_NAME_UPDATE_ERROR, 400)
        end

        if environment.save
          present environment, with: Entities::Environment, current_user: current_user
        else
          render_validation_error!(environment)
        end
      end

      desc 'Delete multiple stopped review apps' do
        detail 'It schedules for deletion multiple environments that have already been stopped and are in the review app folder. The actual deletion is performed after 1 week from the time of execution. By default, it only deletes environments 30 days or older. You can change this default using the `before` parameter.'
        success Entities::EnvironmentBasic
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' },
          { code: 409, message: 'Conflict' }
        ]
        tags environments_tags
      end
      params do
        optional :before, type: Time, desc: "The date before which environments can be deleted. Defaults to 30 days ago. Expected in ISO 8601 format (`YYYY-MM-DDTHH:MM:SSZ`)", default: -> { 30.days.ago }
        optional :limit, type: Integer, desc: "Maximum number of environments to delete. Defaults to 100", default: 100, values: 1..1000
        optional :dry_run, type: Boolean, desc: "Defaults to true for safety reasons. It performs a dry run where no actual deletion will be performed. Set to false to actually delete the environment", default: true
      end
      delete ":id/environments/review_apps" do
        authorize! :read_environment, user_project

        result = ::Environments::ScheduleToDeleteReviewAppsService.new(user_project, current_user, params).execute

        response = {
          scheduled_entries: Entities::EnvironmentBasic.represent(result.scheduled_entries),
          unprocessable_entries: Entities::EnvironmentBasic.represent(result.unprocessable_entries)
        }

        if result.success?
          status result.status
          present response, current_user: current_user
        else
          render_api_error!(response.merge!(message: result.error_message), result.status)
        end
      end

      desc 'Delete an environment' do
        detail 'It returns 204 if the environment was successfully deleted, and 404 if the environment does not exist. This feature was introduced in GitLab 8.11.'
        success Entities::Environment
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[environments]
      end
      params do
        requires :environment_id, type: Integer, desc: 'The ID of the environment'
      end
      delete ':id/environments/:environment_id' do
        authorize! :read_environment, user_project

        environment = user_project.environments.find(params[:environment_id])
        authorize! :destroy_environment, environment

        destroy_conditionally!(environment)
      end

      desc 'Stop an environment' do
        detail 'It returns 200 if the environment was successfully stopped, and 404 if the environment does not exist.'
        success Entities::Environment
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[environments]
      end
      params do
        requires :environment_id, type: Integer, desc: 'The ID of the environment'
        optional :force, type: Boolean, default: false, desc: 'Force environment to stop without executing `on_stop` actions'
      end
      post ':id/environments/:environment_id/stop' do
        authorize! :read_environment, user_project

        environment = user_project.environments.find(params[:environment_id])
        ::Environments::StopService.new(user_project, current_user, declared_params(include_missing: false))
                                 .execute(environment)

        status 200
        present environment, with: Entities::Environment, current_user: current_user
      end

      desc 'Stop stale environments' do
        detail 'It returns `200` if stale environment check was scheduled successfully'
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' }
        ]
        tags %w[environments]
      end
      params do
        requires :before,
                 type: DateTime,
                 desc: 'Stop all environments that were last modified or deployed to before this date.'
      end
      post ':id/environments/stop_stale' do
        authorize! :stop_environment, user_project

        bad_request!('Invalid Date') if params[:before] < 10.years.ago || params[:before] > 1.week.ago

        service_response = ::Environments::StopStaleService.new(user_project, current_user, params.slice(:before)).execute

        if service_response.error?
          status 400
        else
          status 200
        end

        present message: service_response.message
      end

      desc 'Get a specific environment' do
        success Entities::Environment
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[environments]
      end
      params do
        requires :environment_id, type: Integer, desc: 'The ID of the environment'
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
