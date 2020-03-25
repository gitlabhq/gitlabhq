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
      return success if sha256_matches_existing_artifact?(job, params['artifact_type'], artifacts_file)

      artifact, artifact_metadata = build_artifact(job, artifacts_file, params, metadata_file)
      result = parse_artifact(job, artifact)

      return result unless result[:status] == :success

      persist_artifact(job, artifact, artifact_metadata)
    end

    private

    def build_artifact(job, artifacts_file, params, metadata_file)
      expire_in = params['expire_in'] ||
        Gitlab::CurrentSettings.current_application_settings.default_artifacts_expire_in

      artifact = Ci::JobArtifact.new(
        job_id: job.id,
        project: job.project,
        file: artifacts_file,
        file_type: params['artifact_type'],
        file_format: params['artifact_format'],
        file_sha256: artifacts_file.sha256,
        expire_in: expire_in)

      artifact_metadata = if metadata_file
                            Ci::JobArtifact.new(
                              job_id: job.id,
                              project: job.project,
                              file: metadata_file,
                              file_type: :metadata,
                              file_format: :gzip,
                              file_sha256: metadata_file.sha256,
                              expire_in: expire_in)
                          end

      [artifact, artifact_metadata]
    end

    def parse_artifact(job, artifact)
      unless Feature.enabled?(:ci_synchronous_artifact_parsing, job.project, default_enabled: true)
        return success
      end

      case artifact.file_type
      when 'dotenv' then parse_dotenv_artifact(job, artifact)
      else success
      end
    end

    def persist_artifact(job, artifact, artifact_metadata)
      Ci::JobArtifact.transaction do
        artifact.save!
        artifact_metadata&.save!

        # NOTE: The `artifacts_expire_at` column is already deprecated and to be removed in the near future.
        job.update_column(:artifacts_expire_at, artifact.expire_at)
      end

      success
    rescue ActiveRecord::RecordNotUnique => error
      track_exception(error, job, params)
      error('another artifact of the same type already exists', :bad_request)
    rescue *OBJECT_STORAGE_ERRORS => error
      track_exception(error, job, params)
      error(error.message, :service_unavailable)
    rescue => error
      track_exception(error, job, params)
      error(error.message, :bad_request)
    end

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

    def parse_dotenv_artifact(job, artifact)
      Ci::ParseDotenvArtifactService.new(job.project, current_user).execute(artifact)
    end
  end
end
