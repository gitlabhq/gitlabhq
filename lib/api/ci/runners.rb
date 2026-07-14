# frozen_string_literal: true

module API
  module Ci
    class Runners < ::API::Base
      include APIGuard
      include PaginationParams

      before do
        authenticate!
        set_current_organization
      end

      feature_category :runner_core
      urgency :low

      helpers do
        include Gitlab::Utils::StrongMemoize

        params :deprecated_filter_params do
          optional :scope, type: String, values: ::Ci::Runner::AVAILABLE_SCOPES,
            desc: 'Deprecated: Use `type` or `status` instead. The scope of runners to return'
        end

        params :filter_params do
          optional :type, type: String, values: ::Ci::Runner::AVAILABLE_TYPES, desc: 'The type of runners to return'
          optional :paused, type: Boolean,
            desc: 'Whether to include only runners that are accepting or ignoring new jobs'
          optional :status, type: String, values: ::Ci::Runner::AVAILABLE_STATUSES_INCL_DEPRECATED,
            desc: 'The status of runners to return'
          optional :tag_list, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
            desc: 'A list of runner tags', documentation: { example: %w[macos shell] }
          optional :version_prefix, type: String, desc: 'The version prefix of runners to return', documentation: { example: '15.1.' },
            regexp: /^[\d+.]+/

          use :pagination
        end

        def filter_runners(runners, scope, allowed_scopes: ::Ci::Runner::AVAILABLE_SCOPES)
          return runners unless scope.present?

          unless allowed_scopes.include?(scope)
            render_api_error!('Scope contains invalid value', 400)
          end

          # Support deprecated scopes
          if runners.respond_to?("deprecated_#{scope}")
            scope = "deprecated_#{scope}"
          end

          runners.public_send(scope) # rubocop:disable GitlabSecurity/PublicSend
        end

        def apply_filter(runners, params)
          runners = filter_runners(runners, params[:type], allowed_scopes: ::Ci::Runner::AVAILABLE_TYPES)
          runners = filter_runners(runners, params[:status], allowed_scopes: ::Ci::Runner::AVAILABLE_STATUSES_INCL_DEPRECATED)
          runners = filter_runners(runners, params[:paused] ? 'paused' : 'active', allowed_scopes: %w[paused active]) if params.include?(:paused)
          runners = runners.with_version_prefix(params[:version_prefix]) if params[:version_prefix]
          runners = runners.tagged_with(params[:tag_list]) if params[:tag_list]

          runners
        end

        def get_runner(id)
          runner = find_runner(id)
          not_found!('Runner') unless runner
          runner
        end

        # Memoized by id so the runner is loaded once across authorization and
        # the endpoint body.
        def find_runner(id)
          strong_memoize_with(:find_runner, id) { ::Ci::Runner.find_by_id(id) }
        end

        # Authorizes against the runner's own boundary: the instance for instance
        # runners, otherwise its owning group/project. Returns nil when the runner
        # is missing so the authorization service 404s.
        def runner_authz_boundary
          runner = find_runner(params[:id])
          return unless runner
          return :instance if runner.instance_type?

          runner.owner
        end

        def authenticate_show_runner!(runner)
          forbidden!("No access granted") unless can?(current_user, :read_runner, runner)
        end

        def authenticate_update_runner!(runner)
          return if current_user.can_admin_all_resources?

          forbidden!("No access granted") unless can?(current_user, :update_runner, runner)
        end

        def authenticate_delete_runner!(runner)
          return if current_user.can_admin_all_resources?

          forbidden!("Runner associated with more than one project") if runner.belongs_to_more_than_one_project?
          forbidden!("No access granted") unless can?(current_user, :delete_runner, runner)
        end

        def authenticate_enable_runner!(runner)
          forbidden!("Runner is a group runner") if runner.group_type?

          return if current_user.can_admin_all_resources?

          forbidden!("Runner is locked") if runner.locked?
          forbidden!("No access granted") unless can?(current_user, :assign_runner, runner)
        end

        def authenticate_disable_runner!(runner_project)
          not_found!('Runner') unless runner_project

          return if current_user.can_admin_all_resources?

          forbidden!("Runner is locked") if runner_project.runner.locked?
          forbidden!("No access granted") unless can?(current_user, :unassign_runner, runner_project)
        end

        def authenticate_list_runners_jobs!(runner)
          return if current_user.can_read_all_resources?

          forbidden!("No access granted") unless can?(current_user, :read_builds, runner)
        end

        def preload_job_associations(jobs)
          jobs.preload( # rubocop: disable CodeReuse/ActiveRecord -- this preload is tightly related to the endpoint
            :ci_stage,
            :user,
            { pipeline: { project: [:route, { namespace: :route }] } },
            { project: [:route, { namespace: :route }, :ci_cd_settings] }
          )
        end
      end

      allow_access_with_scope :manage_runner, if: ->(request) do
        request.params.key?(:id) && request.path.match?(%r{\A/api/v[34]/runners/})
      end

      resource :runners do
        desc 'List all available runners' do
          detail 'Lists all runners available to the user. For group runners, you must have the ' \
            'Owner role in the owner namespace.'
          summary 'List available runners'
          success Entities::Ci::Runner
          failure [[400, 'Scope contains invalid value'], [401, 'Unauthorized']]
          tags %w[runners]
        end
        params do
          use :deprecated_filter_params
          use :filter_params
        end
        route_setting :authorization, permissions: :read_runner, boundary_type: :user
        get do
          runners = current_user.ci_available_runners.with_api_entity_associations
          runners = filter_runners(runners, params[:scope], allowed_scopes: ::Ci::Runner::AVAILABLE_STATUSES_INCL_DEPRECATED)
          runners = apply_filter(runners, params)

          present paginate(runners), with: Entities::Ci::Runner, current_user: current_user
        end

        desc 'List all runners' do
          detail 'Lists all runners in the GitLab instance (project and shared). You must have ' \
            'either administrator access or auditor access.'
          success Entities::Ci::Runner
          failure [[400, 'Scope contains invalid value'], [401, 'Unauthorized']]
          tags %w[runners]
        end
        params do
          use :deprecated_filter_params
          use :filter_params
        end
        route_setting :authorization, permissions: :read_runner, boundary_type: :instance
        get 'all' do
          authenticated_with_can_read_all_resources!

          runners = ::Ci::Runner.all.with_api_entity_associations
          runners = filter_runners(runners, params[:scope])
          runners = apply_filter(runners, params)

          present paginate(runners), with: Entities::Ci::Runner, current_user: current_user
        end

        desc 'Retrieve details on a runner' do
          detail 'Retrieves details of a runner. Instance runner details are available to all authenticated users ' \
            'through this endpoint. For groups and projects, you must have the Maintainer or Owner role for the ' \
            'associated project or group.'
          success Entities::Ci::RunnerDetails
          failure [[401, 'Unauthorized'], [403, 'No access granted'], [404, 'Runner not found']]
          tags %w[runners]
        end
        params do
          requires :id, type: Integer, desc: 'The ID of a runner'
          optional :include_projects, type: Boolean, desc: 'Include projects in the response. Set to false to improve performance for runners with many projects.', default: true
        end
        route_setting :authorization,
          permissions: :read_runner,
          boundary: -> { runner_authz_boundary },
          boundaries: [{ boundary_type: :instance }, { boundary_type: :group }, { boundary_type: :project }]
        get ':id' do
          runner = get_runner(params[:id])
          authenticate_show_runner!(runner)

          present runner, with: Entities::Ci::RunnerDetails, current_user: current_user, include_projects: params[:include_projects]
        end

        desc 'List all managers for a runner' do
          detail 'List all managers for a specified runner.'
          success Entities::Ci::RunnerManager
          failure [[403, 'Forbidden']]
          tags %w[runners]
        end
        params do
          requires :id, type: Integer, desc: 'The ID of a runner'
        end
        route_setting :authorization,
          permissions: :read_runner,
          boundary: -> { runner_authz_boundary },
          boundaries: [{ boundary_type: :instance }, { boundary_type: :group }, { boundary_type: :project }]
        get ':id/managers' do
          runner = get_runner(params[:id])
          authenticate_show_runner!(runner)

          present runner.runner_managers, with: Entities::Ci::RunnerManager
        end

        desc 'Get projects associated with a runner' do
          summary "List runner's projects"
          detail 'Get a paginated list of all projects associated with the specified runner. ' \
                 'Access is restricted based on user permissions.'
          success Entities::BasicProjectDetails
          failure [[401, 'Unauthorized'], [403, 'No access granted'], [404, 'Runner not found']]
          tags %w[runners projects]
        end
        params do
          requires :id, type: Integer, desc: 'The ID of a runner'
          use :pagination
        end
        route_setting :authorization,
          permissions: :read_runner,
          boundary: -> { runner_authz_boundary },
          boundaries: [{ boundary_type: :instance }, { boundary_type: :group }, { boundary_type: :project }]
        get ':id/projects' do
          runner = get_runner(params[:id])
          authenticate_show_runner!(runner)

          projects = ProjectsFinder.new(
            current_user: current_user,
            project_ids_relation: runner.projects.select(:id)
          ).execute

          projects = Entities::BasicProjectDetails.preload_relation(projects)
          present paginate(projects), with: Entities::BasicProjectDetails
        end

        desc 'Update a runner' do
          detail 'Updates a specified runner.'
          summary "Update details of a runner"
          success Entities::Ci::RunnerDetails
          failure [[400, 'Bad Request'], [401, 'Unauthorized'], [403, 'No access granted'], [404, 'Runner not found']]
          tags %w[runners]
        end
        params do
          requires :id, type: Integer, desc: 'The ID of a runner'
          optional :description, type: String, desc: 'The description of the runner'
          optional :active, type: Boolean, desc: 'Deprecated: Use `paused` instead. Flag indicating whether the runner is allowed to receive jobs'
          optional :paused, type: Boolean, desc: 'Specifies if the runner should ignore new jobs'
          optional :tag_list, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
            desc: 'The list of tags for a runner', documentation: { example: %w[macos shell] }
          optional :run_untagged, type: Boolean, desc: 'Specifies if the runner can execute untagged jobs'
          optional :locked, type: Boolean, desc: 'Specifies if the runner is locked'
          optional :access_level, type: String, values: ::Ci::Runner.access_levels.keys,
            desc: 'The access level of the runner'
          optional :maximum_timeout, type: Integer,
            desc: 'Maximum timeout that limits the amount of time (in seconds) that runners can run jobs'
          optional :maintenance_note, type: String,
            desc: 'Free-form maintenance notes for the runner (1024 characters)'
          at_least_one_of :description, :active, :paused, :tag_list, :run_untagged, :locked, :access_level, :maximum_timeout, :maintenance_note
          mutually_exclusive :active, :paused
        end
        route_setting :authorization,
          permissions: :update_runner,
          boundary: -> { runner_authz_boundary },
          boundaries: [{ boundary_type: :instance }, { boundary_type: :group }, { boundary_type: :project }]
        put ':id' do
          runner = get_runner(params.delete(:id))
          authenticate_update_runner!(runner)
          params[:active] = !params.delete(:paused) if params.include?(:paused)
          update_service = ::Ci::Runners::UpdateRunnerService.new(current_user, runner)

          if update_service.execute(declared_params(include_missing: false)).success?
            present runner, with: Entities::Ci::RunnerDetails, current_user: current_user
          else
            render_validation_error!(runner)
          end
        end

        desc 'Delete a runner' do
          detail 'Deletes a specified runner.'
          summary 'Delete a runner'
          success Entities::Ci::Runner
          failure [[401, 'Unauthorized'], [403, 'No access granted'],
            [403, 'Runner associated with more than one project'], [404, 'Runner not found'],
            [412, 'Precondition Failed']]
          tags %w[runners]
        end
        params do
          requires :id, type: Integer, desc: 'The ID of a runner'
        end
        route_setting :authorization,
          permissions: :delete_runner,
          boundary: -> { runner_authz_boundary },
          boundaries: [{ boundary_type: :instance }, { boundary_type: :group }, { boundary_type: :project }]
        delete ':id' do
          runner = get_runner(params[:id])

          authenticate_delete_runner!(runner)

          destroy_conditionally!(runner) { ::Ci::Runners::UnregisterRunnerService.new(runner, current_user).execute }
        end

        desc 'List all jobs processed by a runner' do
          detail 'Lists all jobs that are being processed or were processed by a specified runner. The list of jobs ' \
            'is limited to projects where the user has the Reporter, Developer, Maintainer, or Owner role.'
          success Entities::Ci::JobBasicWithProject
          failure [[401, 'Unauthorized'], [403, 'No access granted'], [404, 'Runner not found']]
          tags %w[runners jobs]
        end
        params do
          requires :id, type: Integer, desc: 'The ID of a runner'
          optional :system_id, type: String, desc: 'System ID associated with the runner manager'
          optional :status, type: String, desc: 'Status of the job', values: ::Ci::Build::AVAILABLE_STATUSES
          optional :order_by, type: String, desc: 'Order by `id`', values: ::Ci::RunnerJobsFinder::ALLOWED_INDEXED_COLUMNS
          optional :sort, type: String, values: %w[asc desc], default: 'desc', desc: 'Sort by `asc` or `desc` order. ' \
            'Specify `order_by` as well, including for `id`'
          optional :cursor, type: String, desc: 'Cursor for obtaining the next set of records'
          use :pagination
        end
        route_setting :authorization,
          permissions: :read_runner,
          boundary: -> { runner_authz_boundary },
          boundaries: [{ boundary_type: :instance }, { boundary_type: :group }, { boundary_type: :project }]
        get ':id/jobs' do
          runner = get_runner(params[:id])
          authenticate_list_runners_jobs!(runner)

          # Optimize query when filtering by runner managers by not asking for count
          paginator_params = params[:pagination] == :keyset || params[:system_id].blank? ? {} : { without_count: true }

          jobs = ::Ci::RunnerJobsFinder.new(runner, current_user, params).execute
          jobs = preload_job_associations(jobs)
          jobs = paginate_with_strategies(jobs, paginator_params: paginator_params)
          jobs.each(&:commit) # batch loads all commits in the page

          present jobs, with: Entities::Ci::JobBasicWithProject
        end

        desc 'Reset an authentication token for a runner' do
          detail 'Resets the authentication token for a specified runner.'
          summary "Reset runner's authentication token"
          success Entities::Ci::ResetTokenResult
          failure [[403, 'No access granted'], [404, 'Runner not found'], [422, 'Unprocessable Entity']]
          tags %w[runners]
        end
        params do
          requires :id, type: Integer, desc: 'The ID of the runner'
        end
        route_setting :authorization,
          permissions: :update_runner,
          boundary: -> { runner_authz_boundary },
          boundaries: [{ boundary_type: :instance }, { boundary_type: :group }, { boundary_type: :project }]
        post ':id/reset_authentication_token' do
          runner = get_runner(params[:id])
          authenticate_update_runner!(runner)

          result = ::Ci::Runners::ResetAuthenticationTokenService.new(runner: runner, current_user: current_user).execute
          error!(result.message, result.reason) if result.error?

          present runner.token_with_expiration, with: Entities::Ci::ResetTokenResult
        end
      end

      params do
        requires :id,
          types: [String, Integer],
          desc: 'The ID or URL-encoded path of the project owned by the authenticated user'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        before { authorize! :read_runners, user_project }

        desc 'List all runners for a project' do
          detail 'Lists all runners available in the project, including from ancestor groups and any allowed ' \
            'instance runners. Prerequisites: - You must be an administrator of the GitLab instance or have at least ' \
            'the Maintainer or Auditor role for the target project.'
          summary "List project's runners"
          detail 'List all runners available in the project, including from ancestor groups ' \
                 'and any allowed shared runners.'
          success Entities::Ci::Runner
          failure [[400, 'Scope contains invalid value'], [403, 'No access granted']]
          tags %w[runners projects]
        end
        params do
          use :deprecated_filter_params
          use :filter_params
        end
        route_setting :authorization, permissions: :read_runner, boundary_type: :project
        get ':id/runners' do
          runners = ::Ci::Runner.owned_or_instance_wide(user_project.id).with_api_entity_associations
          # scope is deprecated (for project runners), however api documentation still supports it.
          # Not including them in `apply_filter` method as it's not supported for group runners
          runners = filter_runners(runners, params[:scope])
          runners = apply_filter(runners, params)

          present paginate(runners), with: Entities::Ci::Runner, current_user: current_user
        end

        desc 'Assign a runner to a project' do
          detail 'Assigns an available project runner to a project.'
          success Entities::Ci::Runner
          failure [[400, 'Bad Request'],
            [403, 'No access granted'], [403, 'Runner is a group runner'], [403, 'Runner is locked'],
            [404, 'Runner not found']]
          tags %w[runners projects]
        end
        params do
          requires :runner_id, type: Integer, desc: 'The ID of a runner'
        end
        route_setting :authorization, permissions: :assign_runner, boundary_type: :project
        post ':id/runners' do
          authorize! :create_runners, user_project # Ensure the user is allowed to create a runner on the target project

          runner = get_runner(params[:runner_id])
          authenticate_enable_runner!(runner)

          result = ::Ci::Runners::AssignRunnerService.new(runner, user_project, current_user).execute
          if result.success?
            present runner, with: Entities::Ci::Runner, current_user: current_user
          else
            render_api_error_with_reason!(:bad_request, result.message, result.reason)
          end
        end

        desc 'Unassign a runner from a project' do
          detail 'Unassigns a specified project runner from a project. You cannot unassign a runner from the owner ' \
            'project. Use the delete a runner operation instead.'
          success Entities::Ci::Runner
          failure [[400, 'Bad Request'],
            [403, 'You cannot unassign a runner from the owner project. Delete the runner instead'],
            [404, 'Runner not found'], [412, 'Precondition Failed']]
          tags %w[runners projects]
        end
        params do
          requires :runner_id, type: Integer, desc: 'The ID of a runner'
        end
        route_setting :authorization, permissions: :unassign_runner, boundary_type: :project
        delete ':id/runners/:runner_id' do
          runner_project = user_project.runner_projects.find_by_runner_id(params[:runner_id])
          authenticate_disable_runner!(runner_project)

          destroy_conditionally!(runner_project) do
            response = ::Ci::Runners::UnassignRunnerService.new(runner_project, current_user).execute
            forbidden!(response.message) if response.error?
          end
        end
      end

      params do
        requires :id, type: String, desc: 'The ID of a group'
      end
      resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        before { authorize! :read_runners, user_group }

        desc 'List all runners in a group' do
          detail 'Lists all runners available in a specified group and any ancestor groups, including any allowed ' \
            'instance runners.'
          success Entities::Ci::Runner
          failure [[400, 'Scope contains invalid value'], [403, 'Forbidden']]
          tags %w[runners groups]
        end
        params do
          use :filter_params
        end
        route_setting :authorization, permissions: :read_runner, boundary_type: :group
        get ':id/runners' do
          runners = ::Ci::Runner.group_or_instance_wide(user_group).with_api_entity_associations
          runners = apply_filter(runners, params)

          present paginate(runners), with: Entities::Ci::Runner, current_user: current_user
        end
      end

      resource :runners do
        before { authenticate_non_get! }

        desc 'Reset the runner registration token for the instance' do
          detail 'Resets the runner registration token for the GitLab instance.'
          success Entities::Ci::ResetTokenResult
          failure [[403, 'Forbidden']]
          tags %w[runners groups]
        end
        route_setting :authorization, permissions: :reset_runner_registration_token, boundary_type: :instance
        post 'reset_registration_token' do
          authorize! :update_runners_registration_token, ApplicationSetting.current

          ::Ci::Runners::ResetRegistrationTokenService.new(ApplicationSetting.current, current_user).execute
          present ApplicationSetting.current_without_cache.runners_registration_token_with_expiration, with: Entities::Ci::ResetTokenResult
        end
      end

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        before { authenticate_non_get! }

        desc 'Reset the runner registration token for a project' do
          detail 'Resets the runner registration token for a specified project.'
          success Entities::Ci::ResetTokenResult
          failure [[401, 'Unauthorized'], [403, 'Forbidden'], [404, 'Project Not Found']]
          tags %w[runners projects]
        end
        route_setting :authorization, permissions: :reset_runner_registration_token, boundary_type: :project
        post ':id/runners/reset_registration_token' do
          project = find_project! user_project.id
          authorize! :update_runners_registration_token, project

          project.reset_runners_token!
          present project.runners_token_with_expiration, with: Entities::Ci::ResetTokenResult
        end
      end

      params do
        requires :id, type: String, desc: 'The ID of a group'
      end
      resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        before { authenticate_non_get! }

        desc 'Reset the runner registration token for a group' do
          detail "Resets the runner registration token for a specified group."
          success Entities::Ci::ResetTokenResult
          failure [[401, 'Unauthorized'], [403, 'Forbidden'], [404, 'Group Not Found']]
          tags %w[runners groups]
        end
        route_setting :authorization, permissions: :reset_runner_registration_token, boundary_type: :group
        post ':id/runners/reset_registration_token' do
          group = find_group! user_group.id
          authorize! :update_runners_registration_token, group

          group.reset_runners_token!
          present group.runners_token_with_expiration, with: Entities::Ci::ResetTokenResult
        end
      end
    end
  end
end
