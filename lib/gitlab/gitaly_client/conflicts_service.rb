# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class ConflictsService
      include Gitlab::EncodingHelper
      include WithFeatureFlagActors

      MAX_MSG_SIZE = 128.kilobytes.freeze

      def initialize(repository, our_commit_oid, their_commit_oid)
        @gitaly_repo = repository.gitaly_repository
        @repository = repository
        @our_commit_oid = our_commit_oid
        @their_commit_oid = their_commit_oid

        self.repository_actor = repository
      end

      def list_conflict_files(allow_tree_conflicts: false, skip_content: false)
        request = Gitaly::ListConflictFilesRequest.new(
          repository: @gitaly_repo,
          our_commit_oid: @our_commit_oid,
          their_commit_oid: @their_commit_oid,
          allow_tree_conflicts: allow_tree_conflicts,
          skip_content: skip_content
        )
        response = gitaly_client_call(@repository.storage, :conflicts_service, :list_conflict_files, request, timeout: GitalyClient.long_timeout)
        GitalyClient::ConflictFilesStitcher.new(response, @gitaly_repo)
      end

      def conflicts?
        list_conflict_files(skip_content: true).any?

      rescue GRPC::FailedPrecondition, GRPC::Unknown
        # The server raises FailedPrecondition when it encounters
        # ConflictSideMissing, which means a conflict exists but its `theirs` or
        # `ours` data is nil due to a non-existent file in one of the trees.
        #
        # GRPC::Unknown comes from Rugged::ReferenceError and Rugged::OdbError.
        true
      end

      def resolve_conflicts(target_repository, resolution, source_branch, target_branch)
        reader = binary_io(resolution.files.to_json)

        req_enum = Enumerator.new do |y|
          header = resolve_conflicts_request_header(target_repository, resolution, source_branch, target_branch)
          y.yield Gitaly::ResolveConflictsRequest.new(header: header)

          until reader.eof?
            chunk = reader.read(MAX_MSG_SIZE)

            y.yield Gitaly::ResolveConflictsRequest.new(files_json: chunk)
          end
        end

        response = gitaly_client_call(@repository.storage, :conflicts_service, :resolve_conflicts, req_enum, remote_storage: target_repository.storage, timeout: GitalyClient.long_timeout)

        if response.resolution_error.present?
          raise Gitlab::Git::Conflict::Resolver::ResolutionError, response.resolution_error
        end
      end

      private

      def resolve_conflicts_request_header(target_repository, resolution, source_branch, target_branch)
        Gitaly::ResolveConflictsRequestHeader.new(
          repository: @gitaly_repo,
          our_commit_oid: @our_commit_oid,
          target_repository: target_repository.gitaly_repository,
          their_commit_oid: @their_commit_oid,
          source_branch: encode_binary(source_branch),
          target_branch: encode_binary(target_branch),
          commit_message: encode_binary(resolution.commit_message),
          user: Gitlab::Git::User.from_gitlab(resolution.user).to_gitaly,
          timestamp: Google::Protobuf::Timestamp.new(seconds: Time.now.utc.to_i)
        )
      end
    end
  end
end
