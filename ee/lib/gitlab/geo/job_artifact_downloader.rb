module Gitlab
  module Geo
    # This class is responsible for:
    #   * Finding a ::Ci::JobArtifact record
    #   * Requesting and downloading the JobArtifact's file from the primary
    #   * Returning a detailed Result
    #
    # TODO: Rearrange things so this class does not inherit FileDownloader
    class JobArtifactDownloader < FileDownloader
      def execute
        job_artifact = ::Ci::JobArtifact.find_by(id: object_db_id)
        return fail_before_transfer unless job_artifact.present?

        transfer = ::Gitlab::Geo::JobArtifactTransfer.new(job_artifact)
        Result.from_transfer_result(transfer.download_from_primary)
      end
    end
  end
end
