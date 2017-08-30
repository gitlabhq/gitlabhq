module Gitlab
  module GitalyClient
    class BlobService
      def initialize(repository)
        @gitaly_repo = repository.gitaly_repository
      end

      def get_blob(oid:, limit:)
        request = Gitaly::GetBlobRequest.new(
          repository: @gitaly_repo,
          oid: oid,
          limit: limit
        )
        response = GitalyClient.call(@gitaly_repo.storage_name, :blob_service, :get_blob, request)

        data = ''
        blob = nil
        response.each do |msg|
          if blob.nil?
            blob = msg
          end

          data << msg.data
        end

        return nil if blob.oid.blank?

        Gitlab::Git::Blob.new(
          id: blob.oid,
          size: blob.size,
          data: data,
          binary: Gitlab::Git::Blob.binary?(data)
        )
      end
    end
  end
end
