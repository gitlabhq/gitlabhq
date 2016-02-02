module API
  # Runners API
  class Runners < Grape::API
    before { authenticate! }

    resource :runners do
      # Get available shared runners
      #
      # Example Request:
      #   GET /runners
      get do
        runners =
          if current_user.is_admin?
            Ci::Runner.all
          else
            current_user.ci_authorized_runners
          end

        runners = filter_runners(runners, params[:scope])
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
        can_show_runner?(runner) unless current_user.is_admin?

        present runner, with: Entities::RunnerDetails
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
        can_update_runner?(runner) unless current_user.is_admin?

        attrs = attributes_for_keys [:description, :active, :tag_list]
        if runner.update(attrs)
          present runner, with: Entities::RunnerDetails
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
        can_delete_runner?(runner)
        runner.destroy!

        present runner, with: Entities::RunnerDetails
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
      post ':id/runners/:runner_id' do
        runner = get_runner(params[:runner_id])
        can_enable_runner?(runner)
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
        forbidden!("Can't disable runner - only one project associated with it. Please remove runner instead") if runner.projects.count == 1

        runner_project.destroy

        present runner, with: Entities::Runner
      end
    end

    helpers do
      def filter_runners(runners, scope)
        return runners unless scope.present?

        available_scopes = ::Ci::Runner::AVAILABLE_SCOPES
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

      def can_show_runner?(runner)
        return true if runner.is_shared
        forbidden!("Can't show runner's details - no access granted") unless user_can_access_runner?(runner)
      end

      def can_update_runner?(runner)
        return true if current_user.is_admin?
        forbidden!("Can't update shared runner") if runner.is_shared?
        forbidden!("Can't update runner - no access granted") unless user_can_access_runner?(runner)
      end

      def can_delete_runner?(runner)
        return true if current_user.is_admin?
        forbidden!("Can't delete shared runner") if runner.is_shared?
        forbidden!("Can't delete runner - associated with more than one project") if runner.projects.count > 1
        forbidden!("Can't delete runner - no access granted") unless user_can_access_runner?(runner)
      end

      def can_enable_runner?(runner)
        forbidden!("Can't enable shared runner directly") if runner.is_shared?
        return true if current_user.is_admin?
        forbidden!("Can't update runner - no access granted") unless user_can_access_runner?(runner)
      end

      def user_can_access_runner?(runner)
        runner.projects.inject(false) do |final, project|
          final || abilities.allowed?(current_user, :admin_project, project)
        end
      end
    end
  end
end
