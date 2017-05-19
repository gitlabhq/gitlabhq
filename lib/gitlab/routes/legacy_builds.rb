
module Gitlab
  module Routes
    class LegacyBuilds
      include Gitlab::Routing.url_helpers
      include GitlabRoutingHelper

      def initialize(map)
        @map = map
      end

      def draw
        redirect_artifacts = @map.redirect(&method(:redirect_artifacts))
        redirect_builds = @map.redirect(&method(:redirect_builds))

        @map.get '/builds(/:id)/artifacts/*action', to: redirect_artifacts,
                                                    as: 'legacy_artifacts',
                                                    format: false

        @map.get '/builds(/:id(/*action))', to: redirect_builds,
                                            as: 'legacy_builds',
                                            format: false
      end

      private

      def redirect_artifacts(params, req)
        if params[:id]
          project = fake_project(*params.values_at(:namespace_id, :project_id))

          artifacts_action_path(params[:action], project, params[:id])
        else
          latest_succeeded_namespace_project_artifacts_path(params[:namespace_id], params[:project_id], params[:action], job: req.GET[:job])
        end
      end

      def redirect_builds(params, req)
        args = params.values_at(:namespace_id, :project_id, :id).compact

        if params[:id]
          case params[:action]
          when 'status'
            status_namespace_project_job_path(*args, format: params[:format])
          when 'trace'
            trace_namespace_project_job_path(*args, format: params[:format])
          when 'raw'
            raw_namespace_project_job_path(*args)
          else # show
            namespace_project_job_path(*args)
          end
        else # index
          namespace_project_jobs_path(*args)
        end
      end

      def fake_project(namespace_id, project_id)
        Struct.new(:namespace, :to_param).new(namespace_id, project_id)
      end
    end
  end
end
