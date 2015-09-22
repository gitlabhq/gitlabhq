module Ci
  module API
    # Builds API
    class Builds < Grape::API
      resource :builds do
        # Runs oldest pending build by runner - Runners only
        #
        # Parameters:
        #   token (required) - The uniq token of runner
        #
        # Example Request:
        #   POST /builds/register
        post "register" do
          authenticate_runner!
          update_runner_last_contact
          required_attributes! [:token]
          not_found! unless current_runner.active?

          build = Ci::RegisterBuildService.new.execute(current_runner)

          if build
            update_runner_info
            present build, with: Entities::Build
          else
            not_found!
          end
        end

        # Update an existing build - Runners only
        #
        # Parameters:
        #   id (required) - The ID of a project
        #   state (optional) - The state of a build
        #   trace (optional) - The trace of a build
        # Example Request:
        #   PUT /builds/:id
        put ":id" do
          authenticate_runner!
          update_runner_last_contact
          build = Ci::Build.where(runner_id: current_runner.id).running.find(params[:id])
          build.update_attributes(trace: params[:trace]) if params[:trace]

          case params[:state].to_s
          when 'success'
            build.success
          when 'failed'
            build.drop
          end
        end
      end
    end
  end
end
