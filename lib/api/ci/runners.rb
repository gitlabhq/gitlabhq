# frozen_string_literal: true

module API
  module Ci
    class Runners < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :runner
      urgency :low

      resource :runners do
        desc 'Get runners available for user' do
          success Entities::Ci::Runner
        end
        params do
          optional :scope, type: String, values: ::Ci::Runner::AVAILABLE_STATUSES,
                          desc: 'The scope of specific runners to show'
          optional :type, type: String, values: ::Ci::Runner::AVAILABLE_TYPES,
                          desc: 'The type of the runners to show'
          optional :paused, type: Boolean, desc: 'Whether to include only runners that are accepting or ignoring new jobs'
          optional :status, type: String, values: ::Ci::Runner::AVAILABLE_STATUSES,
                            desc: 'The status of the runners to show'
          optional :tag_list, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'The tags of the runners to show'
          use :pagination
        end
        get do
          runners = current_user.ci_owned_runners
          runners = filter_runners(runners, params[:scope], allowed_scopes: ::Ci::Runner::AVAILABLE_STATUSES)
          runners = apply_filter(runners, params)

          present paginate(runners), with: Entities::Ci::Runner
        end

        desc 'Get all runners - shared and specific' do
          success Entities::Ci::Runner
        end
        params do
          optional :scope, type: String, values: ::Ci::Runner::AVAILABLE_SCOPES,
                          desc: 'The scope of specific runners to show'
          optional :type, type: String, values: ::Ci::Runner::AVAILABLE_TYPES,
                          desc: 'The type of the runners to show'
          optional :paused, type: Boolean, desc: 'Whether to include only runners that are accepting or ignoring new jobs'
          optional :status, type: String, values: ::Ci::Runner::AVAILABLE_STATUSES,
                            desc: 'The status of the runners to show'
          optional :tag_list, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'The tags of the runners to show'
          use :pagination
        end
        get 'all' do
          authenticated_as_admin!

          runners = ::Ci::Runner.all
          runners = filter_runners(runners, params[:scope])
          runners = apply_filter(runners, params)

          present paginate(runners), with: Entities::Ci::Runner
        end

        desc "Get runner's details" do
          success Entities::Ci::RunnerDetails
        end
        params do
          requires :id, type: Integer, desc: 'The ID of the runner'
        end
        get ':id' do
          runner = get_runner(params[:id])
          authenticate_show_runner!(runner)

          present runner, with: Entities::Ci::RunnerDetails, current_user: current_user
        end

        desc "Update runner's details" do
          success Entities::Ci::RunnerDetails
        end
        params do
          requires :id, type: Integer, desc: 'The ID of the runner'
          optional :description, type: String, desc: 'The description of the runner'
          optional :active, type: Boolean, desc: 'Deprecated: Use `:paused` instead. Flag indicating whether the runner is allowed to receive jobs'
          optional :paused, type: Boolean, desc: 'Flag indicating whether the runner should ignore new jobs'
          optional :tag_list, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'The list of tags for a runner'
          optional :run_untagged, type: Boolean, desc: 'Flag indicating whether the runner can execute untagged jobs'
          optional :locked, type: Boolean, desc: 'Flag indicating the runner is locked'
          optional :access_level, type: String, values: ::Ci::Runner.access_levels.keys,
                                  desc: 'The access_level of the runner'
          optional :maximum_timeout, type: Integer, desc: 'Maximum timeout set when this Runner will handle the job'
          at_least_one_of :description, :active, :paused, :tag_list, :run_untagged, :locked, :access_level, :maximum_timeout
          mutually_exclusive :active, :paused
        end
        put ':id' do
          runner = get_runner(params.delete(:id))
          authenticate_update_runner!(runner)
          params[:active] = !params.delete(:paused) if params.include?(:paused)
          update_service = ::Ci::Runners::UpdateRunnerService.new(runner)

          if update_service.update(declared_params(include_missing: false))
            present runner, with: Entities::Ci::RunnerDetails, current_user: current_user
          else
            render_validation_error!(runner)
          end
        end

        desc 'Remove a runner' do
          success Entities::Ci::Runner
        end
        params do
          requires :id, type: Integer, desc: 'The ID of the runner'
        end
        delete ':id' do
          runner = get_runner(params[:id])

          authenticate_delete_runner!(runner)

          destroy_conditionally!(runner) { ::Ci::Runners::UnregisterRunnerService.new(runner, current_user).execute }
        end

        desc 'List jobs running on a runner' do
          success Entities::Ci::JobBasicWithProject
        end
        params do
          requires :id, type: Integer, desc: 'The ID of the runner'
          optional :status, type: String, desc: 'Status of the job', values: ::Ci::Build::AVAILABLE_STATUSES
          optional :order_by, type: String, desc: 'Order by `id` or not', values: ::Ci::RunnerJobsFinder::ALLOWED_INDEXED_COLUMNS
          optional :sort, type: String, values: %w[asc desc], default: 'desc', desc: 'Sort by asc (ascending) or desc (descending)'
          use :pagination
        end
        get ':id/jobs' do
          runner = get_runner(params[:id])
          authenticate_list_runners_jobs!(runner)

          jobs = ::Ci::RunnerJobsFinder.new(runner, current_user, params).execute

          present paginate(jobs), with: Entities::Ci::JobBasicWithProject
        end

        desc 'Reset runner authentication token' do
          success Entities::Ci::ResetTokenResult
        end
        params do
          requires :id, type: Integer, desc: 'The ID of the runner'
        end
        post ':id/reset_authentication_token' do
          runner = get_runner(params[:id])
          authenticate_update_runner!(runner)

          runner.reset_token!
          present runner.token_with_expiration, with: Entities::Ci::ResetTokenResult
        end
      end

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        before { authorize_admin_project }

        desc 'Get runners available for project' do
          success Entities::Ci::Runner
        end
        params do
          optional :scope, type: String, values: ::Ci::Runner::AVAILABLE_SCOPES,
                          desc: 'The scope of specific runners to show'
          optional :type, type: String, values: ::Ci::Runner::AVAILABLE_TYPES,
                          desc: 'The type of the runners to show'
          optional :paused, type: Boolean, desc: 'Whether to include only runners that are accepting or ignoring new jobs'
          optional :status, type: String, values: ::Ci::Runner::AVAILABLE_STATUSES,
                            desc: 'The status of the runners to show'
          optional :tag_list, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'The tags of the runners to show'
          use :pagination
        end
        get ':id/runners' do
          runners = ::Ci::Runner.owned_or_instance_wide(user_project.id)
          # scope is deprecated (for project runners), however api documentation still supports it.
          # Not including them in `apply_filter` method as it's not supported for group runners
          runners = filter_runners(runners, params[:scope])
          runners = apply_filter(runners, params)

          present paginate(runners), with: Entities::Ci::Runner
        end

        desc 'Enable a runner for a project' do
          success Entities::Ci::Runner
        end
        params do
          requires :runner_id, type: Integer, desc: 'The ID of the runner'
        end
        post ':id/runners' do
          runner = get_runner(params[:runner_id])
          authenticate_enable_runner!(runner)

          if ::Ci::Runners::AssignRunnerService.new(runner, user_project, current_user).execute
            present runner, with: Entities::Ci::Runner
          else
            render_validation_error!(runner)
          end
        end

        desc "Disable project's runner" do
          success Entities::Ci::Runner
        end
        params do
          requires :runner_id, type: Integer, desc: 'The ID of the runner'
        end
        # rubocop: disable CodeReuse/ActiveRecord
        delete ':id/runners/:runner_id' do
          runner_project = user_project.runner_projects.find_by(runner_id: params[:runner_id])
          not_found!('Runner') unless runner_project

          runner = runner_project.runner
          forbidden!("Only one project associated with the runner. Please remove the runner instead") if runner.runner_projects.count == 1

          destroy_conditionally!(runner_project)
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end

      params do
        requires :id, type: String, desc: 'The ID of a group'
      end
      resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        before { authorize_admin_group }

        desc 'Get runners available for group' do
          success Entities::Ci::Runner
        end
        params do
          optional :type, type: String, values: ::Ci::Runner::AVAILABLE_TYPES,
                  desc: 'The type of the runners to show'
          optional :paused, type: Boolean, desc: 'Whether to include only runners that are accepting or ignoring new jobs'
          optional :status, type: String, values: ::Ci::Runner::AVAILABLE_STATUSES,
                  desc: 'The status of the runners to show'
          optional :tag_list, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'The tags of the runners to show'
          use :pagination
        end
        get ':id/runners' do
          runners = ::Ci::Runner.group_or_instance_wide(user_group)
          runners = apply_filter(runners, params)

          present paginate(runners), with: Entities::Ci::Runner
        end
      end

      resource :runners do
        before { authenticate_non_get! }

        desc 'Resets runner registration token' do
          success Entities::Ci::ResetTokenResult
        end
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

        desc 'Resets runner registration token' do
          success Entities::Ci::ResetTokenResult
        end
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

        desc 'Resets runner registration token' do
          success Entities::Ci::ResetTokenResult
        end
        post ':id/runners/reset_registration_token' do
          group = find_group! user_group.id
          authorize! :update_runners_registration_token, group

          group.reset_runners_token!
          present group.runners_token_with_expiration, with: Entities::Ci::ResetTokenResult
        end
      end

      helpers do
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
          runners = filter_runners(runners, params[:status], allowed_scopes: ::Ci::Runner::AVAILABLE_STATUSES)
          runners = filter_runners(runners, params[:paused] ? 'paused' : 'active', allowed_scopes: %w[paused active]) if params.include?(:paused)
          runners = runners.tagged_with(params[:tag_list]) if params[:tag_list]

          runners
        end

        def get_runner(id)
          runner = ::Ci::Runner.find(id)
          not_found!('Runner') unless runner
          runner
        end

        def authenticate_show_runner!(runner)
          return if runner.instance_type? || current_user.admin?

          forbidden!("No access granted") unless can?(current_user, :read_runner, runner)
        end

        def authenticate_update_runner!(runner)
          return if current_user.admin?

          forbidden!("No access granted") unless can?(current_user, :update_runner, runner)
        end

        def authenticate_delete_runner!(runner)
          return if current_user.admin?

          forbidden!("Runner associated with more than one project") if runner.runner_projects.count > 1
          forbidden!("No access granted") unless can?(current_user, :delete_runner, runner)
        end

        def authenticate_enable_runner!(runner)
          forbidden!("Runner is a group runner") if runner.group_type?

          return if current_user.admin?

          forbidden!("Runner is locked") if runner.locked?
          forbidden!("No access granted") unless can?(current_user, :assign_runner, runner)
        end

        def authenticate_list_runners_jobs!(runner)
          return if current_user.admin?

          forbidden!("No access granted") unless can?(current_user, :read_runner, runner)
        end
      end
    end
  end
end
