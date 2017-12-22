module Gitlab
  module Geo
    class JobArtifactDownloader < FileDownloader
      def execute
        job_artifact = ::Ci::JobArtifact.find_by(id: object_db_id)
        return unless job_artifact.present?

        transfer = ::Gitlab::Geo::JobArtifactTransfer.new(job_artifact)
        transfer.download_from_primary
      end
    end
  end
end
