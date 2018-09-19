module API
  class Runners < Grape::API
    include PaginationParams

    before { authenticate! }

    resource :runners do
      desc 'Get runners available for user' do
        success Entities::Runner
      end
      params do
        optional :scope, type: String, values: Ci::Runner::AVAILABLE_STATUSES,
                         desc: 'The scope of specific runners to show'
        use :pagination
      end
      get do
        runners = filter_runners(current_user.ci_owned_runners, params[:scope], allowed_scopes: Ci::Runner::AVAILABLE_STATUSES)
        present paginate(runners), with: Entities::Runner
      end

      desc 'Get all runners - shared and specific' do
        success Entities::Runner
      end
      params do
        optional :scope, type: String, values: Ci::Runner::AVAILABLE_SCOPES,
                         desc: 'The scope of specific runners to show'
        use :pagination
      end
      get 'all' do
        authenticated_as_admin!
        runners = filter_runners(Ci::Runner.all, params[:scope])
        present paginate(runners), with: Entities::Runner
      end

      desc "Get runner's details" do
        success Entities::RunnerDetails
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the runner'
      end
      get ':id' do
        runner = get_runner(params[:id])
        authenticate_show_runner!(runner)

        present runner, with: Entities::RunnerDetails, current_user: current_user
      end

      desc "Update runner's details" do
        success Entities::RunnerDetails
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the runner'
        optional :description, type: String, desc: 'The description of the runner'
        optional :active, type: Boolean, desc: 'The state of a runner'
        optional :tag_list, type: Array[String], desc: 'The list of tags for a runner'
        optional :run_untagged, type: Boolean, desc: 'Flag indicating the runner can execute untagged jobs'
        optional :locked, type: Boolean, desc: 'Flag indicating the runner is locked'
        optional :access_level, type: String, values: Ci::Runner.access_levels.keys,
                                desc: 'The access_level of the runner'
        optional :maximum_timeout, type: Integer, desc: 'Maximum timeout set when this Runner will handle the job'
        at_least_one_of :description, :active, :tag_list, :run_untagged, :locked, :access_level, :maximum_timeout
      end
      put ':id' do
        runner = get_runner(params.delete(:id))
        authenticate_update_runner!(runner)
        update_service = Ci::UpdateRunnerService.new(runner)

        if update_service.update(declared_params(include_missing: false))
          present runner, with: Entities::RunnerDetails, current_user: current_user
        else
          render_validation_error!(runner)
        end
      end

      desc 'Remove a runner' do
        success Entities::Runner
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the runner'
      end
      delete ':id' do
        runner = get_runner(params[:id])

        authenticate_delete_runner!(runner)

        destroy_conditionally!(runner)
      end

      desc 'List jobs running on a runner' do
        success Entities::JobBasicWithProject
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the runner'
        optional :status, type: String, desc: 'Status of the job', values: Ci::Build::AVAILABLE_STATUSES
        use :pagination
      end
      get  ':id/jobs' do
        runner = get_runner(params[:id])
        authenticate_list_runners_jobs!(runner)

        jobs = RunnerJobsFinder.new(runner, params).execute

        present paginate(jobs), with: Entities::JobBasicWithProject
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      before { authorize_admin_project }

      desc 'Get runners available for project' do
        success Entities::Runner
      end
      params do
        optional :scope, type: String, values: Ci::Runner::AVAILABLE_SCOPES,
                         desc: 'The scope of specific runners to show'
        use :pagination
      end
      get ':id/runners' do
        runners = filter_runners(Ci::Runner.owned_or_instance_wide(user_project.id), params[:scope])
        present paginate(runners), with: Entities::Runner
      end

      desc 'Enable a runner for a project' do
        success Entities::Runner
      end
      params do
        requires :runner_id, type: Integer, desc: 'The ID of the runner'
      end
      post ':id/runners' do
        runner = get_runner(params[:runner_id])
        authenticate_enable_runner!(runner)

        if runner.assign_to(user_project)
          present runner, with: Entities::Runner
        else
          render_validation_error!(runner)
        end
      end

      desc "Disable project's runner" do
        success Entities::Runner
      end
      params do
        requires :runner_id, type: Integer, desc: 'The ID of the runner'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ':id/runners/:runner_id' do
        runner_project = user_project.runner_projects.find_by(runner_id: params[:runner_id])
        not_found!('Runner') unless runner_project

        runner = runner_project.runner
        forbidden!("Only one project associated with the runner. Please remove the runner instead") if runner.projects.count == 1

        destroy_conditionally!(runner_project)
      end
      # rubocop: enable CodeReuse/ActiveRecord
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

      def get_runner(id)
        runner = Ci::Runner.find(id)
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

        forbidden!("Runner associated with more than one project") if runner.projects.count > 1
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
