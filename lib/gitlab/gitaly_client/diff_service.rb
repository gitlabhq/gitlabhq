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
    end
  end
end
