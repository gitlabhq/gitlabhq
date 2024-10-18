# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class BlobService
      include Gitlab::EncodingHelper
      include WithFeatureFlagActors

      def initialize(repository)
        @gitaly_repo = repository.gitaly_repository

        self.repository_actor = repository
      end

      def get_blob(oid:, limit:)
        request = Gitaly::GetBlobRequest.new(
          repository: @gitaly_repo,
          oid: oid,
          limit: limit
        )
        response = gitaly_client_call(@gitaly_repo.storage_name, :blob_service, :get_blob, request, timeout: GitalyClient.fast_timeout)
        consume_blob_response(response)
      end

      def list_all_blobs(limit: nil, bytes_limit: 0, dynamic_timeout: nil, ignore_alternate_object_directories: false)
        response = list_all_blobs_response(limit: limit, bytes_limit: bytes_limit, dynamic_timeout: dynamic_timeout, ignore_alternate_object_directories: ignore_alternate_object_directories)
        GitalyClient::BlobsStitcher.new(GitalyClient::ListBlobsAdapter.new(response))
      end

      def list_oversized_blobs(file_size_limit_megabytes: 100, limit: nil, bytes_limit: 0, dynamic_timeout: nil, ignore_alternate_object_directories: false)
        response = list_all_blobs_response(limit: limit, bytes_limit: bytes_limit, dynamic_timeout: dynamic_timeout, ignore_alternate_object_directories: ignore_alternate_object_directories)
        file_size_limit_bytes = ::Gitlab::Utils.try_megabytes_to_bytes(file_size_limit_megabytes)
        BlobsStitcher.new(GitalyClient::ListBlobsAdapter.new(response), filter_function: ->(blob) { blob.size&.> file_size_limit_bytes })
      end

      def list_blobs(revisions, limit: 0, bytes_limit: 0, with_paths: false, dynamic_timeout: nil)
        request = Gitaly::ListBlobsRequest.new(
          repository: @gitaly_repo,
          revisions: Array.wrap(revisions),
          limit: limit,
          bytes_limit: bytes_limit,
          with_paths: with_paths
        )

        timeout =
          if dynamic_timeout
            [dynamic_timeout, GitalyClient.medium_timeout].min
          else
            GitalyClient.medium_timeout
          end

        response = gitaly_client_call(@gitaly_repo.storage_name, :blob_service, :list_blobs, request, timeout: timeout)
        GitalyClient::BlobsStitcher.new(GitalyClient::ListBlobsAdapter.new(response))
      end

      def batch_lfs_pointers(blob_ids)
        return [] if blob_ids.empty?

        request = Gitaly::GetLFSPointersRequest.new(
          repository: @gitaly_repo,
          blob_ids: blob_ids
        )

        response = gitaly_client_call(@gitaly_repo.storage_name, :blob_service, :get_lfs_pointers, request, timeout: GitalyClient.medium_timeout)
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

        response = gitaly_client_call(
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

        response = gitaly_client_call(
          @gitaly_repo.storage_name,
          :blob_service,
          :get_blobs,
          request,
          timeout: GitalyClient.fast_timeout
        )
        map_blob_types(response)
      end

      def get_new_lfs_pointers(revisions, limit, not_in, dynamic_timeout = nil)
        request, rpc = create_new_lfs_pointers_request(revisions, limit, not_in)

        timeout =
          if dynamic_timeout
            [dynamic_timeout, GitalyClient.medium_timeout].min
          else
            GitalyClient.medium_timeout
          end

        response = gitaly_client_call(
          @gitaly_repo.storage_name,
          :blob_service,
          rpc,
          request,
          timeout: timeout
        )
        map_lfs_pointers(response)
      end

      def get_all_lfs_pointers
        request = Gitaly::ListLFSPointersRequest.new(
          repository: @gitaly_repo,
          revisions: [encode_binary("--all")]
        )

        response = gitaly_client_call(@gitaly_repo.storage_name, :blob_service, :list_lfs_pointers, request, timeout: GitalyClient.medium_timeout)
        map_lfs_pointers(response)
      end

      private

      def list_all_blobs_response(limit: nil, bytes_limit: 0, dynamic_timeout: nil, ignore_alternate_object_directories: false)
        repository = @gitaly_repo

        if ignore_alternate_object_directories
          repository = @gitaly_repo.dup.tap do |g_repo|
            g_repo.git_alternate_object_directories = Google::Protobuf::RepeatedField.new(:string)
          end
        end

        request = Gitaly::ListAllBlobsRequest.new(
          repository: repository,
          limit: limit,
          bytes_limit: bytes_limit
        )

        timeout =
          if dynamic_timeout
            [dynamic_timeout, GitalyClient.medium_timeout].min
          else
            GitalyClient.medium_timeout
          end

        Gitlab::GitalyClient.call(repository.storage_name, :blob_service, :list_all_blobs, request, timeout: timeout)
      end

      def create_new_lfs_pointers_request(revisions, limit, not_in)
        # If the check happens for a change which is using a quarantine
        # environment for incoming objects, then we can avoid doing the
        # necessary graph walk to detect only new LFS pointers and instead scan
        # through all quarantined objects.
        git_env = ::Gitlab::Git::HookEnv.all(@gitaly_repo.gl_repository)
        if git_env['GIT_OBJECT_DIRECTORY_RELATIVE'].present?
          repository = @gitaly_repo.dup
          repository.git_alternate_object_directories = Google::Protobuf::RepeatedField.new(:string)

          request = Gitaly::ListAllLFSPointersRequest.new(
            repository: repository,
            limit: limit || 0
          )

          [request, :list_all_lfs_pointers]
        else
          revisions = Array.wrap(revisions)
          revisions += if not_in.nil? || not_in == :all
                         ["--not", "--all"]
                       else
                         not_in.prepend "--not"
                       end

          request = Gitaly::ListLFSPointersRequest.new(
            repository: @gitaly_repo,
            limit: limit || 0,
            revisions: revisions.map { |rev| encode_binary(rev) }
          )

          [request, :list_lfs_pointers]
        end
      end

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
