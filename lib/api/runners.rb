module API
  # Runners API
  class Runners < Grape::API
    before { authenticate! }

    resource :runners do
      # Get runners available for user
      #
      # Example Request:
      #   GET /runners
      get do
        runners = filter_runners(current_user.ci_authorized_runners, params[:scope], without: ['specific', 'shared'])
        present paginate(runners), with: Entities::Runner
      end

      # Get all runners - shared and specific
      #
      # Example Request:
      #   GET /runners/all
      get 'all' do
        authenticated_as_admin!
        runners = filter_runners(Ci::Runner.all, params[:scope])
        present paginate(runners), with: Entities::Runner
      end

      # Get runner's details
      #
      # Parameters:
      #   id (required) - The ID of ther runner
      # Example Request:
      #   GET /runners/:id
      get ':id' do
        runner = get_runner(params[:id])
        authenticate_show_runner!(runner)

        present runner, with: Entities::RunnerDetails, current_user: current_user
      end

      # Update runner's details
      #
      # Parameters:
      #   id (required) - The ID of ther runner
      #   description (optional) - Runner's description
      #   active (optional) - Runner's status
      #   tag_list (optional) - Array of tags for runner
      # Example Request:
      #   PUT /runners/:id
      put ':id' do
        runner = get_runner(params[:id])
        authenticate_update_runner!(runner)

        attrs = attributes_for_keys [:description, :active, :tag_list]
        if runner.update(attrs)
          present runner, with: Entities::RunnerDetails, current_user: current_user
        else
          render_validation_error!(runner)
        end
      end

      # Remove runner
      #
      # Parameters:
      #   id (required) - The ID of ther runner
      # Example Request:
      #   DELETE /runners/:id
      delete ':id' do
        runner = get_runner(params[:id])
        authenticate_delete_runner!(runner)
        runner.destroy!

        present runner, with: Entities::Runner
      end
    end

    resource :projects do
      before { authorize_admin_project }

      # Get runners available for project
      #
      # Example Request:
      #   GET /projects/:id/runners
      get ':id/runners' do
        runners = filter_runners(Ci::Runner.owned_or_shared(user_project.id), params[:scope])
        present paginate(runners), with: Entities::Runner
      end

      # Enable runner for project
      #
      # Parameters:
      #   id (required) - The ID of the project
      #   runner_id (required) - The ID of the runner
      # Example Request:
      #   POST /projects/:id/runners/:runner_id
      post ':id/runners' do
        required_attributes! [:runner_id]

        runner = get_runner(params[:runner_id])
        authenticate_enable_runner!(runner)
        Ci::RunnerProject.create(runner: runner, project: user_project)

        present runner, with: Entities::Runner
      end

      # Disable project's runner
      #
      # Parameters:
      #   id (required) - The ID of the project
      #   runner_id (required) - The ID of the runner
      # Example Request:
      #   DELETE /projects/:id/runners/:runner_id
      delete ':id/runners/:runner_id' do
        runner_project = user_project.runner_projects.find_by(runner_id: params[:runner_id])
        not_found!('Runner') unless runner_project

        runner = runner_project.runner
        forbidden!("Only one project associated with the runner. Please remove the runner instead") if runner.projects.count == 1

        runner_project.destroy

        present runner, with: Entities::Runner
      end
    end

    helpers do
      def filter_runners(runners, scope, options = {})
        return runners unless scope.present?

        available_scopes = ::Ci::Runner::AVAILABLE_SCOPES
        if options[:without]
          available_scopes = available_scopes - options[:without]
        end

        if (available_scopes & [scope]).empty?
          render_api_error!('Scope contains invalid value', 400)
        end

        runners.send(scope)
      end

      def get_runner(id)
        runner = Ci::Runner.find(id)
        not_found!('Runner') unless runner
        runner
      end

      def authenticate_show_runner!(runner)
        return if runner.is_shared || current_user.is_admin?
        forbidden!("No access granted") unless user_can_access_runner?(runner)
      end

      def authenticate_update_runner!(runner)
        return if current_user.is_admin?
        forbidden!("Runner is shared") if runner.is_shared?
        forbidden!("No access granted") unless user_can_access_runner?(runner)
      end

      def authenticate_delete_runner!(runner)
        return if current_user.is_admin?
        forbidden!("Runner is shared") if runner.is_shared?
        forbidden!("Runner associated with more than one project") if runner.projects.count > 1
        forbidden!("No access granted") unless user_can_access_runner?(runner)
      end

      def authenticate_enable_runner!(runner)
        forbidden!("Runner is shared") if runner.is_shared?
        return if current_user.is_admin?
        forbidden!("No access granted") unless user_can_access_runner?(runner)
      end

      def user_can_access_runner?(runner)
        current_user.ci_authorized_runners.exists?(runner.id)
      end
    end
  end
end
