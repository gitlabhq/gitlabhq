# frozen_string_literal: true

module API
  module Ci
    class JobArtifacts < ::API::Base
      include PaginationParams

      helpers ::API::Helpers::ProjectStatsRefreshConflictsHelpers

      before { authenticate_non_get! }

      feature_category :job_artifacts

      # EE::API::Ci::JobArtifacts would override the following helpers
      helpers do
        def authorize_download_artifacts!
          authorize_read_builds!
        end

        def audit_download(build, filename); end

        # Returns a strong ETag derived from the archive's sha256 (and an
        # optional entry path, for the raw file endpoints), or nil when no
        # sha256 is available. Passed to the presenter helpers via the
        # `etag:` kwarg. See gitlab-org/gitlab#371991.
        def artifact_etag(build, path: nil)
          archive = build&.job_artifacts_archive
          return unless archive&.file_sha256

          digest = path ? Digest::SHA256.hexdigest("#{archive.file_sha256}:#{path}") : archive.file_sha256
          %("#{digest}")
        end
      end

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Retrieve job artifacts' do
          detail 'Retrieves the artifacts archive for the latest successful job on a specified branch or tag.'
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags ['job_artifacts']
        end
        params do
          requires :ref_name, type: String,
            desc: 'Branch or tag name in repository. `HEAD` or `SHA` references are not supported.'
          requires :job,      type: String, desc: 'The name of the job.'
          optional :job_token, type: String,
            desc: 'To be used with triggers for multi-project pipelines, ' \
                  'available only on Premium and Ultimate tiers.'
          optional :search_recent_successful_pipelines, type: Boolean, default: false,
            desc: 'Search across recent successful pipelines instead of just the latest one.'
        end
        route_setting :authentication, job_token_allowed: true
        route_setting :authorization, job_token_policies: :read_jobs,
          permissions: :download_job_artifact, boundary_type: :project
        get ':id/jobs/artifacts/:ref_name/download',
          urgency: :low,
          requirements: { ref_name: /.+/ } do
          authorize_download_artifacts!

          if params[:search_recent_successful_pipelines]
            latest_build = ::Ci::Build.latest_with_artifacts_for_ref(
              user_project,
              params[:job],
              params[:ref_name]
            )

            not_found!('Job') unless latest_build
          else
            latest_build = user_project.latest_successful_build_for_ref!(params[:job], params[:ref_name])
          end

          authorize_read_job_artifacts!(latest_build)

          not_found! unless latest_build.artifacts_file&.exists?

          audit_download(latest_build, latest_build.artifacts_file.filename)
          present_artifacts_file!(latest_build.artifacts_file, etag: artifact_etag(latest_build))
        end

        desc 'Download a specific file from artifacts archive from a ref' do
          detail 'This feature was introduced in GitLab 11.5'
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags ['job_artifacts']
        end
        params do
          requires :ref_name, type: String,
            desc: 'Branch or tag name in repository. `HEAD` or `SHA` references are not supported.'
          requires :job, type: String, desc: 'The name of the job.'
          requires :artifact_path, type: String, desc: 'Path to a file inside the artifacts archive.'
          optional :job_token, type: String,
            desc: 'To be used with triggers for multi-project pipelines, ' \
                  'available only on Premium and Ultimate tiers.'
          optional :search_recent_successful_pipelines, type: Boolean, default: false,
            desc: 'Search across recent successful pipelines instead of just the latest one.'
        end
        route_setting :authentication, job_token_allowed: true
        route_setting :authorization, job_token_policies: :read_jobs,
          allow_public_access_for_enabled_project_features: [:repository, :builds],
          permissions: :download_job_artifact, boundary_type: :project
        get ':id/jobs/artifacts/:ref_name/raw/*artifact_path',
          urgency: :low,
          requirements: { ref_name: /.+/ }.merge(API::NO_FORMAT_SUFFIX_REQUIREMENT) do
          authorize_download_artifacts!

          if params[:search_recent_successful_pipelines]
            build = ::Ci::Build.latest_with_artifacts_for_ref(
              user_project,
              params[:job],
              params[:ref_name]
            )

            not_found!('Job') unless build
          else
            build = user_project.latest_successful_build_for_ref!(params[:job], params[:ref_name])
          end

          authorize_read_job_artifacts!(build)

          path = Gitlab::Ci::Build::Artifacts::Path
            .new(params[:artifact_path])

          bad_request! unless path.valid?

          send_artifacts_entry(build.artifacts_file, path, etag: artifact_etag(build, path: params[:artifact_path]))
        end

        desc 'Download the artifacts archive from a job' do
          detail 'This feature was introduced in GitLab 8.5'
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags ['job_artifacts']
        end
        params do
          requires :job_id, type: Integer, desc: 'The ID of a job'
          optional :job_token, type: String,
            desc: 'To be used with triggers for multi-project pipelines, ' \
                  'available only on Premium and Ultimate tiers.'
        end
        route_setting :authentication, job_token_allowed: true
        route_setting :authorization, job_token_policies: :read_jobs,
          permissions: :download_job_artifact, boundary_type: :project
        get ':id/jobs/:job_id/artifacts', urgency: :low do
          authorize_download_artifacts!

          build = find_build!(params[:job_id])
          authorize_read_job_artifacts!(build)
          audit_download(build, build.artifacts_file.filename) if build.artifacts_file
          present_artifacts_file!(build.artifacts_file, etag: artifact_etag(build))
        end

        desc 'List all files in an artifacts archive' do
          detail 'Lists all files in a specified artifacts archive without extracting them.'
          success code: 200, model: Entities::Ci::JobArtifactEntry
          is_array true
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[job_artifacts]
        end
        params do
          requires :job_id, type: Integer, desc: 'ID of a job',
            documentation: { example: 42 }
          optional :path, type: String, default: '',
            desc: 'Path to browse in the artifacts archive. Defaults to root directory.',
            documentation: { example: 'coverage/reports' }
          optional :recursive, type: Boolean, default: false, desc: 'If `true`, return all entries recursively.',
            documentation: { example: false }
          optional :job_token, type: String,
            desc: 'CI/CD job token for multi-project pipelines. ' \
                  'Premium and Ultimate only.'
          use :pagination
        end
        route_setting :authentication, job_token_allowed: true
        route_setting :authorization, job_token_policies: :read_jobs,
          permissions: :download_job_artifact, boundary_type: :project
        get ':id/jobs/:job_id/artifacts/tree', urgency: :low do
          authorize_download_artifacts!

          build = find_build!(params[:job_id])
          authorize_read_job_artifacts!(build)

          not_found!('Artifacts') unless build.available_artifacts?
          not_found!('Artifacts metadata') unless build.job_artifacts_metadata&.exists?

          path = params[:path]
          directory = path.present? ? "#{path.delete_suffix('/')}/" : ''

          entry = build.artifacts_metadata_entry(directory, recursive: params[:recursive])
          not_found!('Path') unless entry.exists?

          entries = params[:recursive] ? entry.children : entry.directories(parent: false) + entry.files
          present paginate(::Kaminari.paginate_array(entries)), with: Entities::Ci::JobArtifactEntry
        end

        desc 'Download a specific file from artifacts archive' do
          detail 'This feature was introduced in GitLab 10.0'
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags ['job_artifacts']
        end
        params do
          requires :job_id, type: Integer, desc: 'The ID of a job'
          requires :artifact_path, type: String, desc: 'Path to a file inside the artifacts archive.'
          optional :job_token, type: String,
            desc: 'To be used with triggers for multi-project pipelines, ' \
                  'available only on Premium and Ultimate tiers.'
        end
        route_setting :authentication, job_token_allowed: true
        route_setting :authorization, job_token_policies: :read_jobs,
          permissions: :download_job_artifact, boundary_type: :project
        get ':id/jobs/:job_id/artifacts/*artifact_path',
          urgency: :low,
          requirements: API::NO_FORMAT_SUFFIX_REQUIREMENT do
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
          legacy_send_artifacts_entry(
            build.artifacts_file,
            path,
            etag: artifact_etag(build, path: params[:artifact_path])
          )
        end

        desc 'Retain job artifacts' do
          detail 'Retains job artifacts. Prevents artifacts for a job from being automatically deleted when they ' \
            'reach their expiration date.'
          success ::API::Entities::Ci::Job
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags ['job_artifacts']
        end
        params do
          requires :job_id, type: Integer, desc: 'The ID of a job'
        end
        route_setting :authorization, permissions: :preserve_job_artifact, boundary_type: :project
        post ':id/jobs/:job_id/artifacts/keep' do
          build = find_build!(params[:job_id])
          authorize!(:keep_job_artifacts, build)
          break not_found!(build) unless build.artifacts?

          build.keep_artifacts!

          status 200
          present build, with: ::API::Entities::Ci::Job
        end

        desc 'Delete job artifacts' do
          detail 'Deletes job artifacts from a specified job in a project.'
          success code: 204
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 409, message: 'Conflict' }
          ]
          tags ['job_artifacts']
        end
        params do
          requires :job_id, type: Integer, desc: 'The ID of a job'
        end
        route_setting :authorization, permissions: :delete_job_artifact, boundary_type: :project
        delete ':id/jobs/:job_id/artifacts' do
          authorize_delete_job_artifact!
          build = find_build!(params[:job_id])
          authorize!(:delete_job_artifact, build)

          reject_if_build_artifacts_size_refreshing!(build.project)

          ::Ci::JobArtifacts::DeleteService.new(build).execute

          status :no_content
        end

        desc 'Delete all job artifacts in a project' do
          detail 'Deletes job artifacts from all jobs in a specified project.'
          success code: 202
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 409, message: 'Conflict' }
          ]
          tags ['job_artifacts']
        end
        route_setting :authorization, permissions: :delete_artifact, boundary_type: :project
        delete ':id/artifacts' do
          authorize_delete_job_artifact!

          reject_if_build_artifacts_size_refreshing!(user_project)

          ::Ci::JobArtifacts::DeleteProjectArtifactsService.new(project: user_project).execute

          accepted!
        end
      end
    end
  end
end

API::Ci::JobArtifacts.prepend_mod
