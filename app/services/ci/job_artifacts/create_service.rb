# frozen_string_literal: true

module Ci
  module JobArtifacts
    class CreateService < ::BaseService
      include Gitlab::Utils::UsageData

      LSIF_ARTIFACT_TYPE = 'lsif'

      OBJECT_STORAGE_ERRORS = [
        Errno::EIO,
        Google::Apis::ServerError,
        Signet::RemoteServerError
      ].freeze

      def initialize(job)
        @job = job
        @project = job.project
        @pipeline = job.pipeline
      end

      def authorize(artifact_type:, filesize: nil)
        result = validate_requirements(artifact_type: artifact_type, filesize: filesize)
        return result unless result[:status] == :success

        headers = JobArtifactUploader.workhorse_authorize(
          has_length: false,
          maximum_size: max_size(artifact_type),
          use_final_store_path: true,
          final_store_path_config: { root_hash: project.id }
        )

        if lsif?(artifact_type)
          headers[:ProcessLsif] = true
          track_usage_event('i_source_code_code_intelligence', project.id)
        end

        success(headers: headers)
      end

      def execute(artifacts_file, params, metadata_file: nil)
        result = validate_requirements(artifact_type: params[:artifact_type], filesize: artifacts_file.size)
        return result unless result[:status] == :success

        return success if sha256_matches_existing_artifact?(params[:artifact_type], artifacts_file)

        build_result = build_artifact(artifacts_file, params, metadata_file)
        return build_result unless build_result[:status] == :success

        artifact = build_result[:artifact]
        artifact_metadata = build_result[:artifact_metadata]

        track_artifact_uploader(artifact)

        parse_result = parse_artifact(artifact)
        return parse_result unless parse_result[:status] == :success

        persist_artifact(artifact, artifact_metadata)
      end

      private

      attr_reader :job, :project, :pipeline

      def validate_requirements(artifact_type:, filesize:)
        return too_large_error if too_large?(artifact_type, filesize)

        success
      end

      def too_large?(type, size)
        size > max_size(type) if size
      end

      def lsif?(type)
        type == LSIF_ARTIFACT_TYPE
      end

      def max_size(type)
        Ci::JobArtifact.max_artifact_size(type: type, project: project)
      end

      def too_large_error
        error('file size has reached maximum size limit', :payload_too_large)
      end

      def build_artifact(artifacts_file, params, metadata_file)
        artifact_attributes = {
          job: job,
          project: project,
          expire_in: expire_in(params),
          accessibility: accessibility(params),
          locked: pipeline.locked
        }

        file_attributes = {
          file_type: params[:artifact_type],
          file_format: params[:artifact_format],
          file_sha256: artifacts_file.sha256,
          file: artifacts_file
        }

        artifact = Ci::JobArtifact.new(artifact_attributes.merge(file_attributes))

        artifact_metadata = build_metadata_artifact(artifact, metadata_file) if metadata_file

        success(artifact: artifact, artifact_metadata: artifact_metadata)
      end

      def build_metadata_artifact(job_artifact, metadata_file)
        Ci::JobArtifact.new(
          job: job_artifact.job,
          project: job_artifact.project,
          expire_at: job_artifact.expire_at,
          locked: job_artifact.locked,
          file: metadata_file,
          file_type: :metadata,
          file_format: :gzip,
          file_sha256: metadata_file.sha256,
          accessibility: job_artifact.accessibility
        )
      end

      def expire_in(params)
        params['expire_in'] || Gitlab::CurrentSettings.current_application_settings.default_artifacts_expire_in
      end

      def accessibility(params)
        accessibility = params[:accessibility]

        return accessibility if accessibility.present?

        job.artifact_access_setting_in_config
      end

      def parse_artifact(artifact)
        case artifact.file_type
        when 'dotenv' then parse_dotenv_artifact(artifact)
        when 'annotations' then parse_annotations_artifact(artifact)
        else success
        end
      end

      def persist_artifact(artifact, artifact_metadata)
        job.transaction do
          # NOTE: The `artifacts_expire_at` column is already deprecated and to be removed in the near future.
          # Running it first because in migrations we lock the `ci_builds` table
          # first and then the others. This reduces the chances of deadlocks.
          job.update_column(:artifacts_expire_at, artifact.expire_at)

          artifact.save!
          artifact_metadata&.save!
        end

        success(artifact: artifact)
      rescue ActiveRecord::RecordNotUnique => error
        track_exception(error, artifact.file_type)
        error('another artifact of the same type already exists', :bad_request)
      rescue *OBJECT_STORAGE_ERRORS => error
        track_exception(error, artifact.file_type)
        error(error.message, :service_unavailable)
      rescue StandardError => error
        track_exception(error, artifact.file_type)
        error(error.message, :bad_request)
      end

      def sha256_matches_existing_artifact?(artifact_type, artifacts_file)
        existing_artifact = job.job_artifacts.find_by_file_type(artifact_type)
        return false unless existing_artifact

        existing_artifact.file_sha256 == artifacts_file.sha256
      end

      def track_exception(error, artifact_type)
        Gitlab::ErrorTracking.track_exception(
          error,
          job_id: job.id,
          project_id: job.project_id,
          uploading_type: artifact_type
        )
      end

      def track_artifact_uploader(_artifact)
        # Overridden in EE
      end

      def parse_dotenv_artifact(artifact)
        Ci::ParseDotenvArtifactService.new(project, current_user).execute(artifact)
      end

      def parse_annotations_artifact(artifact)
        Ci::ParseAnnotationsArtifactService.new(project, current_user).execute(artifact)
      end
    end
  end
end

Ci::JobArtifacts::CreateService.prepend_mod
