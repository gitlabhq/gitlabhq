
module Gitlab
  module Routes
    class LegacyBuilds
      def initialize(map)
        @map = map
      end

      def draw
        redirect_builds_to_jobs = @map.redirect(&method(:redirect))

        @map.get '/builds(/:id(/*action))', to: redirect_builds_to_jobs,
                                            as: 'legacy_build',
                                            format: false
      end

      def redirect(params, req)
        args = params.values_at(:namespace_id, :project_id, :id).compact
        url_helpers = Gitlab::Routing.url_helpers

        if params[:id]
          case params[:action]
          when 'status'
            url_helpers.status_namespace_project_job_path(*args, format: params[:format])
          when 'trace'
            url_helpers.trace_namespace_project_job_path(*args, format: params[:format])
          when 'raw'
            url_helpers.raw_namespace_project_job_path(*args)
          when String
            if params[:id] == 'artifacts'
              url_helpers.latest_succeeded_namespace_project_artifacts_path(params[:namespace_id], params[:project_id], params[:action], job: req.GET[:job])
            else
              "#{url_helpers.namespace_project_job_path(*args)}/#{params[:action]}"
            end
          else # show
            url_helpers.namespace_project_job_path(*args)
          end
        else # index
          url_helpers.namespace_project_jobs_path(*args)
        end
      end
    end
  end
end
