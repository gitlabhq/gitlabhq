module API
  # Projects builds API
  class Builds < Grape::API
    before { authenticate! }

    resource :projects do
      # Get a project builds
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   scope (optional) - The scope of builds to show (one of: all, finished, running)
      #   page (optional) - The page number for pagination (default: 1)
      #   per_page (ooptional) - The value of items per page to show (default 30)
      # Example Request:
      #   GET /projects/:id/builds
      get ':id/builds' do
        builds = user_project.builds.order('id DESC')
        builds = filter_builds(builds, params[:scope])
        present paginate(builds), with: Entities::Build
      end

      # Get builds for a specific commit of a project
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   sha (required) - The SHA id of a commit
      # Example Request:
      #   GET /projects/:id/builds/commit/:sha
      get ':id/builds/commit/:sha' do
        builds = user_project.ci_commits.find_by_sha(params[:sha]).builds.order('id DESC')
        builds = filter_builds(builds, params[:scope])
        present paginate(builds), with: Entities::Build
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

        present build, with: Entities::Build
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
    end

    helpers do
      def get_build(id)
        user_project.builds.where(id: id).first
      end

      def filter_builds(builds, scope)
        case scope
        when 'finished'
          builds.finished
        when 'running'
          builds.running
        else
          builds
        end
      end
    end
  end
end
