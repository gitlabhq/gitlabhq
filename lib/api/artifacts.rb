module API
  # Projects artifacts API
  class Artifacts < Grape::API
    before do
      authenticate!
      authorize!(:read_build, user_project)
    end

    resource :projects do
      # Download the artifacts file from ref_name and build_name
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   ref_name (required) - The ref from repository
      #   build_name (required) - The name for the build
      # Example Request:
      #   GET /projects/:id/artifacts/:ref_name/:build_name
      get ':id/artifacts/:ref_name/:build_name',
          requirements: { ref_name: /.+/ } do
        builds = user_project.builds_for(
          params[:build_name], params[:ref_name])

        latest_build = builds.success.latest.first

        if latest_build
          redirect(
            "/projects/#{user_project.id}/builds/#{latest_build.id}/artifacts")
        else
          not_found!
        end
      end
    end
  end
end
