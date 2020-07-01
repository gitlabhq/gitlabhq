# frozen_string_literal: true

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
        response = GitalyClient.call(@gitaly_repo.storage_name, :blob_service, :get_blob, request, timeout: GitalyClient.fast_timeout)
        consume_blob_response(response)
      end

      def batch_lfs_pointers(blob_ids)
        return [] if blob_ids.empty?

        request = Gitaly::GetLFSPointersRequest.new(
          repository: @gitaly_repo,
          blob_ids: blob_ids
        )

        response = GitalyClient.call(@gitaly_repo.storage_name, :blob_service, :get_lfs_pointers, request, timeout: GitalyClient.medium_timeout)
        map_lfs_pointers(response)
      end

      def get_blobs(revision_paths, limit = -1)
        return [] if revision_paths.empty?

        request_revision_paths = revision_paths.map do |rev, path|
          Gitaly::GetBlobsRequest::RevisionPath.new(revision: rev, path: encode_binary(path))
        end

        request = Gitaly::GetBlobsRequest.new(
          repository: @gitaly_repo,
          revision_paths: request_revision_paths,
          limit: limit
        )

        response = GitalyClient.call(
          @gitaly_repo.storage_name,
          :blob_service,
          :get_blobs,
          request,
          timeout: GitalyClient.fast_timeout)

        GitalyClient::BlobsStitcher.new(response)
      end

      def get_blob_types(revision_paths, limit = -1)
        return {} if revision_paths.empty?

        request_revision_paths = revision_paths.map do |rev, path|
          Gitaly::GetBlobsRequest::RevisionPath.new(revision: rev, path: encode_binary(path))
        end

        request = Gitaly::GetBlobsRequest.new(
          repository: @gitaly_repo,
          revision_paths: request_revision_paths,
          limit: limit
        )

        response = GitalyClient.call(
          @gitaly_repo.storage_name,
          :blob_service,
          :get_blobs,
          request,
          timeout: GitalyClient.fast_timeout
        )
        map_blob_types(response)
      end

      def get_new_lfs_pointers(revision, limit, not_in, dynamic_timeout = nil)
        request = Gitaly::GetNewLFSPointersRequest.new(
          repository: @gitaly_repo,
          revision: encode_binary(revision),
          limit: limit || 0
        )

        if not_in.nil? || not_in == :all
          request.not_in_all = true
        else
          request.not_in_refs += not_in
        end

        timeout =
          if dynamic_timeout
            [dynamic_timeout, GitalyClient.medium_timeout].min
          else
            GitalyClient.medium_timeout
          end

        response = GitalyClient.call(
          @gitaly_repo.storage_name,
          :blob_service,
          :get_new_lfs_pointers,
          request,
          timeout: timeout
        )
        map_lfs_pointers(response)
      end

      def get_all_lfs_pointers
        request = Gitaly::GetAllLFSPointersRequest.new(
          repository: @gitaly_repo
        )

        response = GitalyClient.call(@gitaly_repo.storage_name, :blob_service, :get_all_lfs_pointers, request, timeout: GitalyClient.medium_timeout)
        map_lfs_pointers(response)
      end

      private

      def consume_blob_response(response)
        data = []
        blob = nil
        response.each do |msg|
          if blob.nil?
            blob = msg
          end

          data << msg.data
        end

        return if blob.oid.blank?

        data = data.join

        Gitlab::Git::Blob.new(
          id: blob.oid,
          size: blob.size,
          data: data,
          binary: Gitlab::Git::Blob.binary?(data)
        )
      end

      def map_lfs_pointers(response)
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

      def map_blob_types(response)
        types = {}

        response.each do |msg|
          types[msg.path.dup.force_encoding('utf-8')] = msg.type.downcase
        end

        types
      end
    end
  end
end
