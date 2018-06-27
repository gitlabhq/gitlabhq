module API
  class JobArtifacts < Grape::API
    before { authenticate_non_get! }

    # EE::API::JobArtifacts would override the following helpers
    helpers do
      def authorize_download_artifacts!
        authorize_read_builds!
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc 'Download the artifacts archive from a job' do
        detail 'This feature was introduced in GitLab 8.10'
      end
      params do
        requires :ref_name, type: String, desc: 'The ref from repository'
        requires :job,      type: String, desc: 'The name for the job'
      end
      route_setting :authentication, job_token_allowed: true
      get ':id/jobs/artifacts/:ref_name/download',
        requirements: { ref_name: /.+/ } do
        authorize_download_artifacts!

        builds = user_project.latest_successful_builds_for(params[:ref_name])
        latest_build = builds.find_by!(name: params[:job])

        present_carrierwave_file!(latest_build.artifacts_file)
      end

      desc 'Download the artifacts archive from a job' do
        detail 'This feature was introduced in GitLab 8.5'
      end
      params do
        requires :job_id, type: Integer, desc: 'The ID of a job'
      end
      route_setting :authentication, job_token_allowed: true
      get ':id/jobs/:job_id/artifacts' do
        authorize_download_artifacts!

        build = find_build!(params[:job_id])

        present_carrierwave_file!(build.artifacts_file)
      end

      desc 'Download a specific file from artifacts archive' do
        detail 'This feature was introduced in GitLab 10.0'
      end
      params do
        requires :job_id, type: Integer, desc: 'The ID of a job'
        requires :artifact_path, type: String, desc: 'Artifact path'
      end
      get ':id/jobs/:job_id/artifacts/*artifact_path', format: false do
        authorize_read_builds!

        build = find_build!(params[:job_id])
        not_found! unless build.artifacts?

        path = Gitlab::Ci::Build::Artifacts::Path
          .new(params[:artifact_path])
        bad_request! unless path.valid?

        send_artifacts_entry(build, path)
      end

      desc 'Keep the artifacts to prevent them from being deleted' do
        success Entities::Job
      end
      params do
        requires :job_id, type: Integer, desc: 'The ID of a job'
      end
      post ':id/jobs/:job_id/artifacts/keep' do
        authorize_update_builds!

        build = find_build!(params[:job_id])
        authorize!(:update_build, build)
        break not_found!(build) unless build.artifacts?

        build.keep_artifacts!

        status 200
        present build, with: Entities::Job
      end
    end
  end
end
