module Gitlab
  module GitalyClient
    class RepositoryService
      include Gitlab::EncodingHelper

      MAX_MSG_SIZE = 128.kilobytes.freeze

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
        request = Gitaly::ApplyGitattributesRequest.new(repository: @gitaly_repo, revision: encode_binary(revision))
        GitalyClient.call(@storage, :repository_service, :apply_gitattributes, request)
      end

      def fetch_remote(remote, ssh_auth:, forced:, no_tags:, timeout:, prune: true)
        request = Gitaly::FetchRemoteRequest.new(
          repository: @gitaly_repo, remote: remote, force: forced,
          no_tags: no_tags, timeout: timeout, no_prune: !prune
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

      def import_repository(source)
        request = Gitaly::CreateRepositoryFromURLRequest.new(
          repository: @gitaly_repo,
          url: source
        )

        GitalyClient.call(
          @storage,
          :repository_service,
          :create_repository_from_url,
          request,
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

      def squash_in_progress?(squash_id)
        request = Gitaly::IsSquashInProgressRequest.new(
          repository: @gitaly_repo,
          squash_id: squash_id.to_s
        )

        response = GitalyClient.call(
          @storage,
          :repository_service,
          :is_squash_in_progress,
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

      def create_bundle(save_path)
        request = Gitaly::CreateBundleRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(
          @storage,
          :repository_service,
          :create_bundle,
          request,
          timeout: GitalyClient.default_timeout
        )

        File.open(save_path, 'wb') do |f|
          response.each do |message|
            f.write(message.data)
          end
        end
      end

      def create_from_bundle(bundle_path)
        request = Gitaly::CreateRepositoryFromBundleRequest.new(repository: @gitaly_repo)
        enum = Enumerator.new do |y|
          File.open(bundle_path, 'rb') do |f|
            while data = f.read(MAX_MSG_SIZE)
              request.data = data

              y.yield request

              request = Gitaly::CreateRepositoryFromBundleRequest.new
            end
          end
        end

        GitalyClient.call(
          @storage,
          :repository_service,
          :create_repository_from_bundle,
          enum,
          timeout: GitalyClient.default_timeout
        )
      end

      def write_ref(ref_path, ref, old_ref, shell)
        request = Gitaly::WriteRefRequest.new(
          repository: @gitaly_repo,
          ref: ref_path.b,
          revision: ref.b,
          shell: shell
        )
        request.old_revision = old_ref.b unless old_ref.nil?

        response = GitalyClient.call(@storage, :repository_service, :write_ref, request)

        raise Gitlab::Git::CommandError, encode!(response.error) if response.error.present?

        true
      end

      def write_config(full_path:)
        request = Gitaly::WriteConfigRequest.new(repository: @gitaly_repo, full_path: full_path)
        response = GitalyClient.call(
          @storage,
          :repository_service,
          :write_config,
          request,
          timeout: GitalyClient.fast_timeout
        )

        raise Gitlab::Git::OSError.new(response.error) unless response.error.empty?
      end

      def license_short_name
        request = Gitaly::FindLicenseRequest.new(repository: @gitaly_repo)

        response = GitalyClient.call(@storage, :repository_service, :find_license, request, timeout: GitalyClient.fast_timeout)

        response.license_short_name.presence
      end
    end
  end
end
