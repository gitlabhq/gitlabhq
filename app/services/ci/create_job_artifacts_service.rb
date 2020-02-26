# frozen_string_literal: true

module Ci
  class CreateJobArtifactsService < ::BaseService
    ArtifactsExistError = Class.new(StandardError)
    OBJECT_STORAGE_ERRORS = [
      Errno::EIO,
      Google::Apis::ServerError,
      Signet::RemoteServerError
    ].freeze

    def execute(job, artifacts_file, params, metadata_file: nil)
      expire_in = params['expire_in'] ||
        Gitlab::CurrentSettings.current_application_settings.default_artifacts_expire_in

      job.job_artifacts.build(
        project: job.project,
        file: artifacts_file,
        file_type: params['artifact_type'],
        file_format: params['artifact_format'],
        file_sha256: artifacts_file.sha256,
        expire_in: expire_in)

      if metadata_file
        job.job_artifacts.build(
          project: job.project,
          file: metadata_file,
          file_type: :metadata,
          file_format: :gzip,
          file_sha256: metadata_file.sha256,
          expire_in: expire_in)
      end

      if job.update(artifacts_expire_in: expire_in)
        success
      else
        error(job.errors.messages, :bad_request)
      end

    rescue ActiveRecord::RecordNotUnique => error
      return success if sha256_matches_existing_artifact?(job, params['artifact_type'], artifacts_file)

      track_exception(error, job, params)
      error('another artifact of the same type already exists', :bad_request)
    rescue *OBJECT_STORAGE_ERRORS => error
      track_exception(error, job, params)
      error(error.message, :service_unavailable)
    end

    private

    def sha256_matches_existing_artifact?(job, artifact_type, artifacts_file)
      existing_artifact = job.job_artifacts.find_by_file_type(artifact_type)
      return false unless existing_artifact

      existing_artifact.file_sha256 == artifacts_file.sha256
    end

    def track_exception(error, job, params)
      Gitlab::ErrorTracking.track_exception(error,
        job_id: job.id,
        project_id: job.project_id,
        uploading_type: params['artifact_type']
      )
    end
  end
end
