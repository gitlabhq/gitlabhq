# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class DiffService
      include WithFeatureFlagActors

      WHITESPACE_CHANGES = {
        unspecified: Gitaly::DiffBlobsRequest::WhitespaceChanges::WHITESPACE_CHANGES_UNSPECIFIED,
        ignore_spaces: Gitaly::DiffBlobsRequest::WhitespaceChanges::WHITESPACE_CHANGES_IGNORE,
        ignore_all_spaces: Gitaly::DiffBlobsRequest::WhitespaceChanges::WHITESPACE_CHANGES_IGNORE_ALL
      }.freeze

      DIFF_MODES = {
        unspecified: Gitaly::DiffBlobsRequest::DiffMode::DIFF_MODE_UNSPECIFIED,
        word: Gitaly::DiffBlobsRequest::DiffMode::DIFF_MODE_WORD
      }.freeze

      def initialize(repository)
        @gitaly_repo = repository.gitaly_repository
        @storage = repository.storage

        self.repository_actor = repository
      end

      # Requests diffs between blob pairs via Gitaly's DiffBlobs RPC using blob_pairs field.
      #
      # @param blob_pairs [Array<Gitaly::DiffBlobsRequest::BlobPair>] Array of blob ID pairs to diff
      # @param diff_mode [Symbol] Diff output mode (:unspecified, :word)
      # @param whitespace_changes [Symbol] Whitespace handling (:unspecified, :ignore_spaces, :ignore_all_spaces)
      # @param patch_bytes_limit [Integer] Maximum patch size in bytes (0 = unlimited)
      # @return [GitalyClient::DiffBlobsStitcher] Streamed diff responses from Gitaly
      def diff_blobs(
        blob_pairs, diff_mode: DIFF_MODES[:unspecified], whitespace_changes: WHITESPACE_CHANGES[:unspecified],
        patch_bytes_limit: 0
      )
        request = Gitaly::DiffBlobsRequest.new(
          repository: @gitaly_repo,
          blob_pairs: blob_pairs,
          diff_mode: diff_mode,
          whitespace_changes: whitespace_changes,
          patch_bytes_limit: patch_bytes_limit
        )

        response = gitaly_client_call(@storage, :diff_service, :diff_blobs, request,
          timeout: GitalyClient.medium_timeout)

        GitalyClient::DiffBlobsStitcher.new(response)
      end

      # Requests diffs between blob pairs via Gitaly's DiffBlobs RPC using raw_info field.
      # More efficient for large batches of files compared to blob_pairs approach.
      #
      # @param raw_info [Array<Gitaly::ChangedPaths>] Array of changed path information
      # @param diff_mode [Symbol] Diff output mode (:unspecified, :word)
      # @param whitespace_changes [Symbol] Whitespace handling (:unspecified, :ignore_spaces, :ignore_all_spaces)
      # @param patch_bytes_limit [Integer] Maximum patch size in bytes (0 = unlimited)
      # @return [GitalyClient::DiffBlobsStitcher] Streamed diff responses from Gitaly
      def diff_blobs_with_raw_info(
        raw_info,
        diff_mode: DIFF_MODES[:unspecified],
        whitespace_changes: WHITESPACE_CHANGES[:unspecified],
        patch_bytes_limit: 0
      )
        request = Gitaly::DiffBlobsRequest.new(
          repository: @gitaly_repo,
          raw_info: raw_info,
          diff_mode: diff_mode,
          whitespace_changes: whitespace_changes,
          patch_bytes_limit: patch_bytes_limit
        )

        response = gitaly_client_call(@storage, :diff_service, :diff_blobs, request,
          timeout: GitalyClient.medium_timeout)

        GitalyClient::DiffBlobsStitcher.new(response)
      end
    end
  end
end
