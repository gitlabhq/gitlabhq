module Gitlab
  module Geo
    class JobArtifactUploader < FileUploader
      def execute
        job_artifact = ::Ci::JobArtifact.find_by(id: object_db_id)

        unless job_artifact.present?
          return error('Job artifact not found')
        end

        unless job_artifact.file.present? && job_artifact.file.exists?
          return error('Job artifact does not have a file')
        end

        success(job_artifact.file)
      end
    end
  end
end
