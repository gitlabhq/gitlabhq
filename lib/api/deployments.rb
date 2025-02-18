# frozen_string_literal: true

module API
  # Deployments RESTful API endpoints
  class Deployments < ::API::Base
    include PaginationParams

    deployments_tags = %w[deployments]

    before { authenticate! }

    feature_category :continuous_delivery
    urgency :low

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project owned by the authenticated user'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'List project deployments' do
        detail 'Get a list of deployments in a project. This feature was introduced in GitLab 8.11.'
        success Entities::Deployment
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        is_array true
        tags deployments_tags
      end
      params do
        use :pagination

        optional :order_by,
          type: String,
          values: DeploymentsFinder::ALLOWED_SORT_VALUES,
          default: DeploymentsFinder::DEFAULT_SORT_VALUE,
          desc: 'Return deployments ordered by either one of `id`, `iid`, `created_at`, `updated_at` or `ref` fields. Default is `id`'

        optional :sort,
          type: String,
          values: DeploymentsFinder::ALLOWED_SORT_DIRECTIONS,
          default: DeploymentsFinder::DEFAULT_SORT_DIRECTION,
          desc: 'Return deployments sorted in `asc` or `desc` order. Default is `asc`'

        optional :updated_after,
          type: DateTime,
          desc: 'Return deployments updated after the specified date. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`)'

        optional :updated_before,
          type: DateTime,
          desc: 'Return deployments updated before the specified date. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`)'

        optional :finished_after,
          type: DateTime,
          desc: 'Return deployments finished after the specified date. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`)'

        optional :finished_before,
          type: DateTime,
          desc: 'Return deployments finished before the specified date. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`)'

        optional :environment,
          type: String,
          desc: 'The name of the environment to filter deployments by'

        optional :status,
          type: String,
          values: Deployment.statuses.keys,
          desc: 'The status to filter deployments by. One of `created`, `running`, `success`, `failed`, `canceled`, or `blocked`'
      end

      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, job_token_policies: :read_deployments
      get ':id/deployments' do
        authorize! :read_deployment, user_project

        deployments =
          DeploymentsFinder.new(declared_params(include_missing: false).merge(project: user_project))
            .execute.with_api_entity_associations

        present paginate(deployments), with: Entities::Deployment
      rescue DeploymentsFinder::InefficientQueryError => e
        bad_request!(e.message)
      end

      desc 'Get a specific deployment' do
        detail 'This feature was introduced in GitLab 8.11.'
        success Entities::DeploymentExtended
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags deployments_tags
      end
      params do
        requires :deployment_id, type: Integer, desc: 'The ID of the deployment'
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, job_token_policies: :read_deployments
      get ':id/deployments/:deployment_id' do
        authorize! :read_deployment, user_project

        deployment = user_project.deployments.find(params[:deployment_id])

        present deployment, with: Entities::DeploymentExtended
      end

      desc 'Create a deployment' do
        detail 'This feature was introduced in GitLab 12.4.'
        success Entities::DeploymentExtended
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags deployments_tags
      end
      params do
        requires :environment,
          type: String,
          desc: 'The name of the environment to create the deployment for'

        requires :sha,
          type: String,
          desc: 'The SHA of the commit that is deployed'

        requires :ref,
          type: String,
          desc: 'The name of the branch or tag that is deployed'

        requires :tag,
          type: Boolean,
          desc: 'A boolean that indicates if the deployed ref is a tag (`true`) or not (`false`)'

        requires :status,
          type: String,
          desc: 'The status of the deployment that is created. One of `running`, `success`, `failed`, or `canceled`',
          values: %w[running success failed canceled]
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, job_token_policies: [:admin_deployments, :admin_environments]
      post ':id/deployments' do
        authorize!(:create_deployment, user_project)
        authorize!(:create_environment, user_project)

        render_api_error!({ ref: ["The branch or tag does not exist"] }, 400) unless user_project.commit(declared_params[:ref])

        environment = user_project
          .environments
          .find_or_create_by_name(params[:environment])

        unless environment.persisted?
          render_validation_error!(environment)
        end

        authorize!(:create_deployment, environment)

        service = ::Deployments::CreateService
          .new(environment, current_user, declared_params)

        deployment = service.execute

        if deployment.persisted?
          present(deployment, with: Entities::DeploymentExtended, current_user: current_user)
        else
          render_validation_error!(deployment)
        end
      end

      desc 'Update a deployment' do
        detail 'This feature was introduced in GitLab 12.4.'
        success Entities::DeploymentExtended
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags deployments_tags
      end
      params do
        requires :status,
          type: String,
          desc: 'The new status of the deployment. One of `running`, `success`, `failed`, or `canceled`',
          values: %w[running success failed canceled]
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, job_token_policies: :admin_deployments
      put ':id/deployments/:deployment_id' do
        deployment = user_project.deployments.find(params[:deployment_id])

        authorize!(:update_deployment, deployment)

        if deployment.deployable
          forbidden!('Deployments created using GitLab CI can not be updated using the API')
        end

        service = ::Deployments::UpdateService.new(deployment, declared_params)

        if service.execute
          present(deployment, with: Entities::DeploymentExtended, current_user: current_user)
        else
          render_validation_error!(deployment)
        end
      end

      desc 'Delete a specific deployment' do
        detail 'Delete a specific deployment that is not currently the last deployment for an environment or in a running state. This feature was introduced in GitLab 15.3.'
        http_codes [
          [204, 'Deployment destroyed'],
          [403, 'Forbidden'],
          [400, '"Cannot destroy running deployment" or "Deployment currently deployed to environment"']
        ]
        tags deployments_tags
      end
      params do
        requires :deployment_id, type: Integer, desc: 'The ID of the deployment'
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, job_token_policies: :admin_deployments
      delete ':id/deployments/:deployment_id' do
        deployment = user_project.deployments.find(params[:deployment_id])

        authorize!(:destroy_deployment, deployment)

        destroy_conditionally!(deployment) do
          result = ::Ci::Deployments::DestroyService.new(user_project, current_user).execute(deployment)

          if result[:status] == :error
            render_api_error!(result[:message], result[:http_status] || 400)
          end
        end
      end

      helpers Helpers::MergeRequestsHelpers

      desc 'List of merge requests associated with a deployment' do
        detail 'Retrieves the list of merge requests shipped with a given deployment. This feature was introduced in GitLab 12.7.'
        success Entities::MergeRequestBasic
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        is_array true
        tags deployments_tags
      end
      params do
        use :pagination

        requires :deployment_id, type: Integer, desc: 'The ID of the deployment'

        use :merge_requests_base_params
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, job_token_policies: :read_deployments
      get ':id/deployments/:deployment_id/merge_requests' do
        authorize! :read_deployment, user_project

        mr_params = declared_params.merge(deployment_id: params[:deployment_id])
        merge_requests = MergeRequestsFinder.new(current_user, mr_params).execute

        present paginate(merge_requests), { with: Entities::MergeRequestBasic, current_user: current_user }
      end
    end
  end
end

API::Deployments.prepend_mod
