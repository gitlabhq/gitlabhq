module Gitlab
  module Geo
    # This class is responsible for:
    #   * Finding an ::Ci::JobArtifact record
    #   * Returning the necessary response data to send the file back
    #
    # TODO: Rearrange things so this class does not inherit from FileUploader
    class JobArtifactUploader < ::Gitlab::Geo::FileUploader
      def execute
        job_artifact = ::Ci::JobArtifact.find_by(id: object_db_id)

        unless job_artifact.present?
          return error('Job artifact not found')
        end

        unless job_artifact.file.present? && job_artifact.file.exists?
          log_error("Could not upload job artifact because it does not have a file", id: job_artifact.id)

          return file_not_found(job_artifact)
        end

        success(job_artifact.file)
      end
    end
  end
end
