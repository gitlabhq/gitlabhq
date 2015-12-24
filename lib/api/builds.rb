module API
  # Projects builds API
  class Builds < Grape::API
    before { authenticate! }

    resource :projects do
      # Get a project repository commits
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   scope (optional) - The scope of builds to show (one of: all, finished, running)
      #   page (optional) - The page number for pagination (default: 1)
      #   per_page (ooptional) - The value of items per page to show (default 30)
      # Example Request:
      #   GET /projects/:id/builds/all
      get ':id/builds' do
        all_builds = user_project.builds
        builds = all_builds.order('created_at DESC')
        builds =
          case params[:scope]
          when 'all'
            builds
          when 'finished'
            builds.finished
          when 'running'
            builds.running
          when 'pending'
            builds.pending
          when 'success'
            builds.success
          when 'failed'
            builds.failed
          else
            builds.running_or_pending.reverse_order
          end

        page = (params[:page] || 1).to_i
        per_page = (params[:per_page] || 30).to_i

        present builds.page(page).per(per_page), with: Entities::Build
      end

      # Get a specific build of a project
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   build_id (required) - The ID of a build
      # Example Request:
      #   GET /projects/:id/builds/:build_id
      get ':id/builds/:build_id' do
        present get_build(params[:build_id]), with: Entities::Build
      end

      # Get a trace of a specific build of a project
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   build_id (required) - The ID of a build
      # Example Request:
      #   GET /projects/:id/build/:build_id/trace
      get ':id/builds/:build_id/trace' do
        trace = get_build(params[:build_id]).trace
        trace =
          unless trace.nil?
            trace.split("\n")
          else
            []
          end

        present trace
      end
    end

    helpers do
      def get_build(id)
        user_project.builds.where(id: id).first
      end
    end
  end
end
