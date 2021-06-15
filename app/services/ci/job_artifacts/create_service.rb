# frozen_string_literal: true

module Ci
  module JobArtifacts
    class CreateService < ::BaseService
      include Gitlab::Utils::UsageData

      ArtifactsExistError = Class.new(StandardError)

      LSIF_ARTIFACT_TYPE = 'lsif'
      METRICS_REPORT_UPLOAD_EVENT_NAME = 'i_testing_metrics_report_artifact_uploaders'

      OBJECT_STORAGE_ERRORS = [
        Errno::EIO,
        Google::Apis::ServerError,
        Signet::RemoteServerError
      ].freeze

      def initialize(job)
        @job = job
        @project = job.project
      end

      def authorize(artifact_type:, filesize: nil)
        result = validate_requirements(artifact_type: artifact_type, filesize: filesize)
        return result unless result[:status] == :success

        headers = JobArtifactUploader.workhorse_authorize(has_length: false, maximum_size: max_size(artifact_type))

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

        artifact, artifact_metadata = build_artifact(artifacts_file, params, metadata_file)
        result = parse_artifact(artifact)

        track_artifact_uploader(artifact)

        return result unless result[:status] == :success

        persist_artifact(artifact, artifact_metadata, params)
      end

      private

      attr_reader :job, :project

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

      def forbidden_type_error(type)
        error("#{type} artifacts are forbidden", :forbidden)
      end

      def too_large_error
        error('file size has reached maximum size limit', :payload_too_large)
      end

      def build_artifact(artifacts_file, params, metadata_file)
        expire_in = params['expire_in'] ||
          Gitlab::CurrentSettings.current_application_settings.default_artifacts_expire_in

        artifact = Ci::JobArtifact.new(
          job_id: job.id,
          project: project,
          file: artifacts_file,
          file_type: params[:artifact_type],
          file_format: params[:artifact_format],
          file_sha256: artifacts_file.sha256,
          expire_in: expire_in)

        artifact_metadata = if metadata_file
                              Ci::JobArtifact.new(
                                job_id: job.id,
                                project: project,
                                file: metadata_file,
                                file_type: :metadata,
                                file_format: :gzip,
                                file_sha256: metadata_file.sha256,
                                expire_in: expire_in)
                            end

        [artifact, artifact_metadata]
      end

      def parse_artifact(artifact)
        unless Feature.enabled?(:ci_synchronous_artifact_parsing, project, default_enabled: true)
          return success
        end

        case artifact.file_type
        when 'dotenv' then parse_dotenv_artifact(artifact)
        else success
        end
      end

      def persist_artifact(artifact, artifact_metadata, params)
        Ci::JobArtifact.transaction do
          artifact.save!
          artifact_metadata&.save!

          # NOTE: The `artifacts_expire_at` column is already deprecated and to be removed in the near future.
          job.update_column(:artifacts_expire_at, artifact.expire_at)
        end

        success
      rescue ActiveRecord::RecordNotUnique => error
        track_exception(error, params)
        error('another artifact of the same type already exists', :bad_request)
      rescue *OBJECT_STORAGE_ERRORS => error
        track_exception(error, params)
        error(error.message, :service_unavailable)
      rescue StandardError => error
        track_exception(error, params)
        error(error.message, :bad_request)
      end

      def sha256_matches_existing_artifact?(artifact_type, artifacts_file)
        existing_artifact = job.job_artifacts.find_by_file_type(artifact_type)
        return false unless existing_artifact

        existing_artifact.file_sha256 == artifacts_file.sha256
      end

      def track_exception(error, params)
        Gitlab::ErrorTracking.track_exception(error,
          job_id: job.id,
          project_id: job.project_id,
          uploading_type: params[:artifact_type]
        )
      end

      def track_artifact_uploader(artifact)
        return unless artifact.file_type == 'metrics'

        track_usage_event(METRICS_REPORT_UPLOAD_EVENT_NAME, @job.user_id)
      end

      def parse_dotenv_artifact(artifact)
        Ci::ParseDotenvArtifactService.new(project, current_user).execute(artifact)
      end
    end
  end
end
