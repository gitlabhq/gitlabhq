module API
  # Projects builds API
  class Builds < Grape::API
    before { authenticate! }

    resource :projects do
      # Get a project builds
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   scope (optional) - The scope of builds to show (one or array of: pending, running, failed, success, canceled;
      #                      if none provided showing all builds)
      # Example Request:
      #   GET /projects/:id/builds
      get ':id/builds' do
        builds = user_project.builds.order('id DESC')
        builds = filter_builds(builds, params[:scope])

        present paginate(builds), with: Entities::Build,
                                  user_can_download_artifacts: can?(current_user, :download_build_artifacts, user_project)
      end

      # Get builds for a specific commit of a project
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   sha (required) - The SHA id of a commit
      #   scope (optional) - The scope of builds to show (one or array of: pending, running, failed, success, canceled;
      #                      if none provided showing all builds)
      # Example Request:
      #   GET /projects/:id/builds/commit/:sha
      get ':id/builds/commit/:sha' do
        commit = user_project.ci_commits.find_by_sha(params[:sha])
        return not_found! unless commit

        builds = commit.builds.order('id DESC')
        builds = filter_builds(builds, params[:scope])
        present paginate(builds), with: Entities::Build,
                                  user_can_download_artifacts: can?(current_user, :download_build_artifacts, user_project)
      end

      # Get a specific build of a project
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   build_id (required) - The ID of a build
      # Example Request:
      #   GET /projects/:id/builds/:build_id
      get ':id/builds/:build_id' do
        build = get_build(params[:build_id])
        return not_found!(build) unless build

        present build, with: Entities::Build,
                       user_can_download_artifacts: can?(current_user, :download_build_artifacts, user_project)
      end

      # Get a trace of a specific build of a project
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   build_id (required) - The ID of a build
      # Example Request:
      #   GET /projects/:id/build/:build_id/trace
      get ':id/builds/:build_id/trace' do
        build = get_build(params[:build_id])
        return not_found!(build) unless build

        header 'Content-Disposition', "infile; filename=\"#{build.id}.log\""
        content_type 'text/plain'
        env['api.format'] = :binary

        trace = build.trace
        body trace
      end

      # Cancel a specific build of a project
      #
      # parameters:
      #   id (required) - the id of a project
      #   build_id (required) - the id of a build
      # example request:
      #   post /projects/:id/build/:build_id/cancel
      post ':id/builds/:build_id/cancel' do
        authorize_manage_builds!

        build = get_build(params[:build_id])
        return not_found!(build) unless build

        build.cancel

        present build, with: Entities::Build,
                       user_can_download_artifacts: can?(current_user, :download_build_artifacts, user_project)
      end

      # Retry a specific build of a project
      #
      # parameters:
      #   id (required) - the id of a project
      #   build_id (required) - the id of a build
      # example request:
      #   post /projects/:id/build/:build_id/retry
      post ':id/builds/:build_id/retry' do
        authorize_manage_builds!

        build = get_build(params[:build_id])
        return forbidden!('Build is not retryable') unless build && build.retryable?

        build = Ci::Build.retry(build)

        present build, with: Entities::Build,
                       user_can_download_artifacts: can?(current_user, :download_build_artifacts, user_project)
      end
    end

    helpers do
      def get_build(id)
        user_project.builds.where(id: id).first
      end

      def filter_builds(builds, scope)
        available_scopes = Ci::Build.available_statuses
        scope =
          if scope.is_a?(String) || scope.is_a?(Symbol)
            available_scopes & [scope.to_s]
          elsif scope.is_a?(Array)
            available_scopes & scope
          elsif scope.respond_to?(:to_h)
            available_scopes & scope.to_h.values
          else
            []
          end

        return builds if scope.empty?

        builds.where(status: scope)
      end

      def authorize_manage_builds!
        authorize! :manage_builds, user_project
      end
    end
  end
end
