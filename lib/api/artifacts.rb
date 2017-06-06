module API
  class Artifacts < Grape::API
    include PaginationParams

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: { id: %r{[^/]+} } do
      desc 'Download the artifacts file from a job' do
        detail 'This feature was introduced in GitLab 8.5'
      end
      params do
        requires :job_id, type: Integer, desc: 'The ID of a job'
      end
      get ':id/jobs/:job_id/artifacts' do
        load_gitlab_ci_token_user!
        authorize_read_builds!

        build = get_build!(params[:job_id])

        present_artifacts!(build.artifacts_file)
      end

      desc 'Download the artifacts file from a job' do
        detail 'This feature was introduced in GitLab 8.10'
      end
      params do
        requires :ref_name, type: String, desc: 'The ref from repository'
        requires :job,      type: String, desc: 'The name for the job'
      end
      get ':id/jobs/artifacts/:ref_name/download',
        requirements: { ref_name: /.+/ } do
        authenticate!
        authorize_read_builds!

        builds = user_project.latest_successful_builds_for(params[:ref_name])
        latest_build = builds.find_by!(name: params[:job])

        present_artifacts!(latest_build.artifacts_file)
      end

      desc 'Keep the artifacts to prevent them from being deleted' do
        success Entities::Job
      end
      params do
        requires :job_id, type: Integer, desc: 'The ID of a job'
      end
      post ':id/jobs/:job_id/artifacts/keep' do
        authenticate!
        authorize! :update_build, user_project

        build = get_build!(params[:job_id])
        authorize!(:update_build, build)
        return not_found!(build) unless build.artifacts?

        build.keep_artifacts!

        status 200
        present build, with: Entities::Job
      end
    end

    helpers do
      def find_build(id)
        user_project.builds.find_by(id: id)
      end

      def get_build!(id)
        find_build(id) || not_found!
      end

      def authorize_read_builds!
        authorize! :read_build, user_project
      end

      def load_gitlab_ci_token_user!
        @current_user ||=
          begin
            result = ::Auth::JobTokenAuthenticationService.new.execute(params[:gitlab_ci_token])
            result&.actor
          end
      end
    end
  end
end
