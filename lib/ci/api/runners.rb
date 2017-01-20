module Ci
  module API
    # Runners API
    class Runners < Grape::API
      resource :runners do
        # Delete runner
        # Parameters:
        #   token (required) - The unique token of runner
        #
        # Example Request:
        #   GET /runners/delete
        delete "delete" do
          required_attributes! [:token]
          authenticate_runner!
          Ci::Runner.find_by_token(params[:token]).destroy
        end

        # Register a new runner
        #
        # Note: This is an "internal" API called when setting up
        # runners, so it is authenticated differently.
        #
        # Parameters:
        #   token (required) - The unique token of runner
        #
        # Example Request:
        #   POST /runners/register
        post "register" do
          required_attributes! [:token]

          project = nil
          runner =
            if runner_registration_token_valid?
              # Create shared runner. Requires admin access
              Ci::Runner.new(is_shared: true)
            elsif project = Project.find_by(runners_token: params[:token])
              Ci::Runner.new
            end

          return forbidden! unless runner

          attributes = attributes_for_keys(
            [:description, :tag_list, :run_untagged, :locked]
          ).merge(get_runner_version_from_params || {})

          Ci::UpdateRunnerService.new(runner).update(attributes)

          # Assign the specific runner for the project
          project.runners << runner if project

          if runner.id
            present runner, with: Entities::Runner
          else
            not_found!
          end
        end
      end
    end
  end
end
