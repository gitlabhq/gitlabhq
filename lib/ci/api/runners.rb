module Ci
  module API
    class Runners < Grape::API
      resource :runners do
        desc 'Delete a runner'
        params do
          requires :token, type: String, desc: 'The unique token of the runner'
        end
        delete "delete" do
          authenticate_runner!
          Ci::Runner.find_by_token(params[:token]).destroy
        end

        desc 'Register a new runner' do
          success Entities::Runner
        end
        params do
          requires :token, type: String, desc: 'The unique token of the runner'
          optional :description, type: String, desc: 'The description of the runner'
          optional :tag_list, type: Array[String], desc: 'A list of tags the runner should run for'
          optional :run_untagged, type: Boolean, desc: 'Flag if the runner should execute untagged jobs'
          optional :locked, type: Boolean, desc: 'Lock this runner for this specific project'
        end
        post "register" do
          runner_params = declared(params, include_missing: false)

          runner =
            if runner_registration_token_valid?
              # Create shared runner. Requires admin access
              Ci::Runner.create(runner_params.merge(is_shared: true))
            elsif project = Project.find_by(runners_token: runner_params[:token])
              # Create a specific runner for project.
              project.runners.create(runner_params)
            end

          return forbidden! unless runner

          if runner.id
            runner.update(get_runner_version_from_params)
            present runner, with: Entities::Runner
          else
            not_found!
          end
        end
      end
    end
  end
end
