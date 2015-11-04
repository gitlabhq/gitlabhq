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

        # Upload artifact to build - Runners only
        #
        # Parameters:
        #   id (required) - The ID of a build
        #   token (required) - The build authorization token
        # Headers:
        #   X-File - path to locally stored body
        #   X-Filename - real filename
        #   X-Content-Type - real content type
        # Example Request:
        #   POST /builds/:id/artifacts
        post ":id/artifacts" do
          build = Ci::Build.find_by_id(params[:id])
          not_found! unless build
          authenticate_build_token!(build)
          forbidden!('build is not running') unless build.running?

          file = uploaded_file!
          file_to_large! unless file.size < max_artifact_size

          if build.update_attributes(artifact_file: file)
            present build, with: Entities::Build
          else
            render_validation_error!(build)
          end
        end

        # Download the artifacts file from build - Runners only
        #
        # Parameters:
        #   id (required) - The ID of a build
        #   token (required) - The build authorization token
        # Example Request:
        #   GET /builds/:id/artifact
        get ":id/artifact" do
          build = Ci::Build.find_by_id(params[:id])
          not_found! unless build
          authenticate_build_token!(build)

          unless build.artifact_file.file_storage?
            return redirect_to build.artifact_file.url
          end

          unless build.artifact_file.exists?
            not_found!
          end

          present_file!(build.artifact_file.path, build.artifact_file.filename)
        end

        # Remove the artifacts file from build
        #
        # Parameters:
        #   id (required) - The ID of a build
        #   token (required) - The build authorization token
        # Example Request:
        #   DELETE /builds/:id/artifact
        delete ":id/artifact" do
          build = Ci::Build.find_by_id(params[:id])
          not_found! unless build
          authenticate_build_token!(build)
          build.remove_artifact_file!
        end
      end
    end
  end
end
