module Gitlab
  module GitalyClient
    class BlobService
      include Gitlab::EncodingHelper

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

      def batch_lfs_pointers(blob_ids)
        return [] if blob_ids.empty?

        request = Gitaly::GetLFSPointersRequest.new(
          repository: @gitaly_repo,
          blob_ids: blob_ids
        )

        response = GitalyClient.call(@gitaly_repo.storage_name, :blob_service, :get_lfs_pointers, request)

        response.flat_map do |message|
          message.lfs_pointers.map do |lfs_pointer|
            Gitlab::Git::Blob.new(
              id: lfs_pointer.oid,
              size: lfs_pointer.size,
              data: lfs_pointer.data,
              binary: Gitlab::Git::Blob.binary?(lfs_pointer.data)
            )
          end
        end
      end

      def get_blobs(revision_paths, limit = -1)
        return [] if revision_paths.empty?

        revision_paths.map! do |rev, path|
          Gitaly::GetBlobsRequest::RevisionPath.new(revision: rev, path: encode_binary(path))
        end

        request = Gitaly::GetBlobsRequest.new(
          repository: @gitaly_repo,
          revision_paths: revision_paths,
          limit: limit
        )

        response = GitalyClient.call(
          @gitaly_repo.storage_name,
          :blob_service,
          :get_blobs,
          request,
          timeout: GitalyClient.default_timeout
        )

        GitalyClient::BlobsStitcher.new(response)
      end
    end
  end
end
