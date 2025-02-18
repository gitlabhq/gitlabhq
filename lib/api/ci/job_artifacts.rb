# frozen_string_literal: true

module API
  module Ci
    class JobArtifacts < ::API::Base
      helpers ::API::Helpers::ProjectStatsRefreshConflictsHelpers

      before { authenticate_non_get! }

      feature_category :job_artifacts

      # EE::API::Ci::JobArtifacts would override the following helpers
      helpers do
        def authorize_download_artifacts!
          authorize_read_builds!
        end

        def audit_download(build, filename); end
      end

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Download the artifacts archive from a job' do
          detail 'This feature was introduced in GitLab 8.10'
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :ref_name, type: String,
            desc: 'Branch or tag name in repository. `HEAD` or `SHA` references are not supported.'
          requires :job,      type: String, desc: 'The name of the job.'
          optional :job_token, type: String,
            desc: 'To be used with triggers for multi-project pipelines, ' \
                  'available only on Premium and Ultimate tiers.'
        end
        route_setting :authentication, job_token_allowed: true
        route_setting :authorization, job_token_policies: :read_jobs
        get ':id/jobs/artifacts/:ref_name/download',
          urgency: :low,
          requirements: { ref_name: /.+/ } do
          authorize_download_artifacts!

          latest_build = user_project.latest_successful_build_for_ref!(params[:job], params[:ref_name])
          authorize_read_job_artifacts!(latest_build)
          audit_download(latest_build, latest_build.artifacts_file.filename)
          present_artifacts_file!(latest_build.artifacts_file)
        end

        desc 'Download a specific file from artifacts archive from a ref' do
          detail 'This feature was introduced in GitLab 11.5'
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :ref_name, type: String,
            desc: 'Branch or tag name in repository. `HEAD` or `SHA` references are not supported.'
          requires :job, type: String, desc: 'The name of the job.'
          requires :artifact_path, type: String, desc: 'Path to a file inside the artifacts archive.'
          optional :job_token, type: String,
            desc: 'To be used with triggers for multi-project pipelines, ' \
                  'available only on Premium and Ultimate tiers.'
        end
        route_setting :authentication, job_token_allowed: true
        route_setting :authorization, job_token_policies: :read_jobs
        get ':id/jobs/artifacts/:ref_name/raw/*artifact_path',
          urgency: :low,
          format: false,
          requirements: { ref_name: /.+/ } do
          authorize_download_artifacts!

          build = user_project.latest_successful_build_for_ref!(params[:job], params[:ref_name])
          authorize_read_job_artifacts!(build)

          path = Gitlab::Ci::Build::Artifacts::Path
            .new(params[:artifact_path])

          bad_request! unless path.valid?

          send_artifacts_entry(build.artifacts_file, path)
        end

        desc 'Download the artifacts archive from a job' do
          detail 'This feature was introduced in GitLab 8.5'
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :job_id, type: Integer, desc: 'The ID of a job'
          optional :job_token, type: String,
            desc: 'To be used with triggers for multi-project pipelines, ' \
                  'available only on Premium and Ultimate tiers.'
        end
        route_setting :authentication, job_token_allowed: true
        route_setting :authorization, job_token_policies: :read_jobs
        get ':id/jobs/:job_id/artifacts', urgency: :low do
          authorize_download_artifacts!

          build = find_build!(params[:job_id])
          authorize_read_job_artifacts!(build)
          audit_download(build, build.artifacts_file&.filename) if build.artifacts_file
          present_artifacts_file!(build.artifacts_file)
        end

        desc 'Download a specific file from artifacts archive' do
          detail 'This feature was introduced in GitLab 10.0'
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :job_id, type: Integer, desc: 'The ID of a job'
          requires :artifact_path, type: String, desc: 'Path to a file inside the artifacts archive.'
          optional :job_token, type: String,
            desc: 'To be used with triggers for multi-project pipelines, ' \
                  'available only on Premium and Ultimate tiers.'
        end
        route_setting :authentication, job_token_allowed: true
        route_setting :authorization, job_token_policies: :read_jobs
        get ':id/jobs/:job_id/artifacts/*artifact_path', urgency: :low, format: false do
          authorize_download_artifacts!

          build = find_build!(params[:job_id])
          authorize_read_job_artifacts!(build)

          not_found! unless build.available_artifacts?

          path = Gitlab::Ci::Build::Artifacts::Path
            .new(params[:artifact_path])

          bad_request! unless path.valid?

          # This endpoint is being used for Artifact Browser feature that renders the content via pages.
          # Since Content-Type is controlled by Rails and Workhorse, if a wrong
          # content-type is sent, it could cause a regression on pages rendering.
          # See https://gitlab.com/gitlab-org/gitlab/-/issues/357078 for more information.
          legacy_send_artifacts_entry(build.artifacts_file, path)
        end

        desc 'Keep the artifacts to prevent them from being deleted' do
          success ::API::Entities::Ci::Job
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
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
          present build, with: ::API::Entities::Ci::Job
        end

        desc 'Delete the artifacts files from a job' do
          detail 'This feature was introduced in GitLab 11.9'
          success code: 204
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 409, message: 'Conflict' }
          ]
        end
        params do
          requires :job_id, type: Integer, desc: 'The ID of a job'
        end
        delete ':id/jobs/:job_id/artifacts' do
          authorize_destroy_artifacts!
          build = find_build!(params[:job_id])
          authorize!(:destroy_artifacts, build)

          reject_if_build_artifacts_size_refreshing!(build.project)

          ::Ci::JobArtifacts::DeleteService.new(build).execute

          status :no_content
        end

        desc 'Expire the artifacts files from a project' do
          success code: 202
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 409, message: 'Conflict' }
          ]
        end
        delete ':id/artifacts' do
          authorize_destroy_artifacts!

          reject_if_build_artifacts_size_refreshing!(user_project)

          ::Ci::JobArtifacts::DeleteProjectArtifactsService.new(project: user_project).execute

          accepted!
        end
      end
    end
  end
end

API::Ci::JobArtifacts.prepend_mod
