module Gitlab
  module Geo
    class JobArtifactTransfer < Transfer
      def initialize(job_artifact)
        @file_type = :job_artifact
        @file_id = job_artifact.id
        @filename = job_artifact.file.path
        @request_data = job_artifact_request_data(job_artifact)
      end

      private

      def job_artifact_request_data(job_artifact)
        { id: @file_id }
      end
    end
  end
end
