module Gitlab
  module GitalyClient
    class RepositoryService
      include Gitlab::EncodingHelper

      def initialize(repository)
        @repository = repository
        @gitaly_repo = repository.gitaly_repository
        @storage = repository.storage
      end

      def exists?
        request = Gitaly::RepositoryExistsRequest.new(repository: @gitaly_repo)

        response = GitalyClient.call(@storage, :repository_service, :repository_exists, request, timeout: GitalyClient.fast_timeout)

        response.exists
      end

      def garbage_collect(create_bitmap)
        request = Gitaly::GarbageCollectRequest.new(repository: @gitaly_repo, create_bitmap: create_bitmap)
        GitalyClient.call(@storage, :repository_service, :garbage_collect, request)
      end

      def repack_full(create_bitmap)
        request = Gitaly::RepackFullRequest.new(repository: @gitaly_repo, create_bitmap: create_bitmap)
        GitalyClient.call(@storage, :repository_service, :repack_full, request)
      end

      def repack_incremental
        request = Gitaly::RepackIncrementalRequest.new(repository: @gitaly_repo)
        GitalyClient.call(@storage, :repository_service, :repack_incremental, request)
      end

      def repository_size
        request = Gitaly::RepositorySizeRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@storage, :repository_service, :repository_size, request)
        response.size
      end

      def apply_gitattributes(revision)
        request = Gitaly::ApplyGitattributesRequest.new(repository: @gitaly_repo, revision: revision)
        GitalyClient.call(@storage, :repository_service, :apply_gitattributes, request)
      end

      def fetch_remote(remote, ssh_auth:, forced:, no_tags:, timeout:)
        request = Gitaly::FetchRemoteRequest.new(
          repository: @gitaly_repo, remote: remote, force: forced,
          no_tags: no_tags, timeout: timeout
        )

        if ssh_auth&.ssh_import?
          if ssh_auth.ssh_key_auth? && ssh_auth.ssh_private_key.present?
            request.ssh_key = ssh_auth.ssh_private_key
          end

          if ssh_auth.ssh_known_hosts.present?
            request.known_hosts = ssh_auth.ssh_known_hosts
          end
        end

        GitalyClient.call(@storage, :repository_service, :fetch_remote, request)
      end

      def create_repository
        request = Gitaly::CreateRepositoryRequest.new(repository: @gitaly_repo)
        GitalyClient.call(@storage, :repository_service, :create_repository, request)
      end

      def has_local_branches?
        request = Gitaly::HasLocalBranchesRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@storage, :repository_service, :has_local_branches, request, timeout: GitalyClient.fast_timeout)

        response.value
      end

      def find_merge_base(*revisions)
        request = Gitaly::FindMergeBaseRequest.new(
          repository: @gitaly_repo,
          revisions: revisions.map { |r| encode_binary(r) }
        )

        response = GitalyClient.call(@storage, :repository_service, :find_merge_base, request)
        response.base.presence
      end

      def fork_repository(source_repository)
        request = Gitaly::CreateForkRequest.new(
          repository: @gitaly_repo,
          source_repository: source_repository.gitaly_repository
        )

        GitalyClient.call(
          @storage,
          :repository_service,
          :create_fork,
          request,
          remote_storage: source_repository.storage,
          timeout: GitalyClient.default_timeout
        )
      end

      def rebase_in_progress?(rebase_id)
        request = Gitaly::IsRebaseInProgressRequest.new(
          repository: @gitaly_repo,
          rebase_id: rebase_id.to_s
        )

        response = GitalyClient.call(
          @storage,
          :repository_service,
          :is_rebase_in_progress,
          request,
          timeout: GitalyClient.default_timeout
        )

        response.in_progress
      end

      def fetch_source_branch(source_repository, source_branch, local_ref)
        request = Gitaly::FetchSourceBranchRequest.new(
          repository: @gitaly_repo,
          source_repository: source_repository.gitaly_repository,
          source_branch: source_branch.b,
          target_ref: local_ref.b
        )

        response = GitalyClient.call(
          @storage,
          :repository_service,
          :fetch_source_branch,
          request,
          remote_storage: source_repository.storage
        )

        response.result
      end

      def fsck
        request = Gitaly::FsckRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@storage, :repository_service, :fsck, request)

        if response.error.empty?
          return "", 0
        else
          return response.error.b, 1
        end
      end
    end
  end
end
