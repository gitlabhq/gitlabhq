# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class RepositoryService
      include Gitlab::EncodingHelper

      MAX_MSG_SIZE = 128.kilobytes

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

      def cleanup
        request = Gitaly::CleanupRequest.new(repository: @gitaly_repo)
        GitalyClient.call(@storage, :repository_service, :cleanup, request, timeout: GitalyClient.fast_timeout)
      end

      def garbage_collect(create_bitmap, prune:)
        request = Gitaly::GarbageCollectRequest.new(repository: @gitaly_repo, create_bitmap: create_bitmap, prune: prune)
        GitalyClient.call(@storage, :repository_service, :garbage_collect, request, timeout: GitalyClient.long_timeout)
      end

      def repack_full(create_bitmap)
        request = Gitaly::RepackFullRequest.new(repository: @gitaly_repo, create_bitmap: create_bitmap)
        GitalyClient.call(@storage, :repository_service, :repack_full, request, timeout: GitalyClient.long_timeout)
      end

      def repack_incremental
        request = Gitaly::RepackIncrementalRequest.new(repository: @gitaly_repo)
        GitalyClient.call(@storage, :repository_service, :repack_incremental, request, timeout: GitalyClient.long_timeout)
      end

      def repository_size
        request = Gitaly::RepositorySizeRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@storage, :repository_service, :repository_size, request, timeout: GitalyClient.medium_timeout)
        response.size
      end

      def get_object_directory_size
        request = Gitaly::GetObjectDirectorySizeRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@storage, :repository_service, :get_object_directory_size, request, timeout: GitalyClient.medium_timeout)

        response.size
      end

      def apply_gitattributes(revision)
        request = Gitaly::ApplyGitattributesRequest.new(repository: @gitaly_repo, revision: encode_binary(revision))
        GitalyClient.call(@storage, :repository_service, :apply_gitattributes, request, timeout: GitalyClient.fast_timeout)
      rescue GRPC::InvalidArgument => ex
        raise Gitlab::Git::Repository::InvalidRef, ex
      end

      def info_attributes
        request = Gitaly::GetInfoAttributesRequest.new(repository: @gitaly_repo)

        response = GitalyClient.call(@storage, :repository_service, :get_info_attributes, request, timeout: GitalyClient.fast_timeout)
        response.each_with_object([]) do |message, attributes|
          attributes << message.attributes
        end.join
      end

      # rubocop: disable Metrics/ParameterLists
      # The `remote` parameter is going away soonish anyway, at which point the
      # Rubocop warning can be enabled again.
      def fetch_remote(remote, url:, refmap:, ssh_auth:, forced:, no_tags:, timeout:, prune: true, check_tags_changed: false)
        request = Gitaly::FetchRemoteRequest.new(
          repository: @gitaly_repo, remote: remote, force: forced,
          no_tags: no_tags, timeout: timeout, no_prune: !prune,
          check_tags_changed: check_tags_changed
        )

        if url
          request.remote_params = Gitaly::Remote.new(url: url,
                                                     mirror_refmaps: Array.wrap(refmap).map(&:to_s))
        end

        if ssh_auth&.ssh_mirror_url?
          if ssh_auth.ssh_key_auth? && ssh_auth.ssh_private_key.present?
            request.ssh_key = ssh_auth.ssh_private_key
          end

          if ssh_auth.ssh_known_hosts.present?
            request.known_hosts = ssh_auth.ssh_known_hosts
          end
        end

        GitalyClient.call(@storage, :repository_service, :fetch_remote, request, timeout: GitalyClient.long_timeout)
      end
      # rubocop: enable Metrics/ParameterLists

      def create_repository
        request = Gitaly::CreateRepositoryRequest.new(repository: @gitaly_repo)
        GitalyClient.call(@storage, :repository_service, :create_repository, request, timeout: GitalyClient.fast_timeout)
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

        response = GitalyClient.call(@storage, :repository_service, :find_merge_base, request, timeout: GitalyClient.fast_timeout)
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
          timeout: GitalyClient.long_timeout
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
          timeout: GitalyClient.long_timeout
        )
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
          timeout: GitalyClient.fast_timeout
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
          timeout: GitalyClient.long_timeout,
          remote_storage: source_repository.storage
        )

        response.result
      end

      def fsck
        request = Gitaly::FsckRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@storage, :repository_service, :fsck, request, timeout: GitalyClient.long_timeout)

        if response.error.empty?
          ["", 0]
        else
          [response.error.b, 1]
        end
      end

      def create_bundle(save_path)
        gitaly_fetch_stream_to_file(
          save_path,
          :create_bundle,
          Gitaly::CreateBundleRequest,
          GitalyClient.long_timeout
        )
      end

      def backup_custom_hooks(save_path)
        gitaly_fetch_stream_to_file(
          save_path,
          :backup_custom_hooks,
          Gitaly::BackupCustomHooksRequest,
          GitalyClient.default_timeout
        )
      end

      def create_from_bundle(bundle_path)
        gitaly_repo_stream_request(
          bundle_path,
          :create_repository_from_bundle,
          Gitaly::CreateRepositoryFromBundleRequest,
          GitalyClient.long_timeout
        )
      end

      def restore_custom_hooks(custom_hooks_path)
        gitaly_repo_stream_request(
          custom_hooks_path,
          :restore_custom_hooks,
          Gitaly::RestoreCustomHooksRequest,
          GitalyClient.default_timeout
        )
      end

      def create_from_snapshot(http_url, http_auth)
        request = Gitaly::CreateRepositoryFromSnapshotRequest.new(
          repository: @gitaly_repo,
          http_url: http_url,
          http_auth: http_auth
        )

        GitalyClient.call(
          @storage,
          :repository_service,
          :create_repository_from_snapshot,
          request,
          timeout: GitalyClient.long_timeout
        )
      end

      def write_ref(ref_path, ref, old_ref)
        request = Gitaly::WriteRefRequest.new(
          repository: @gitaly_repo,
          ref: ref_path.b,
          revision: ref.b
        )
        request.old_revision = old_ref.b unless old_ref.nil?

        GitalyClient.call(@storage, :repository_service, :write_ref, request, timeout: GitalyClient.fast_timeout)
      end

      def set_config(entries)
        return if entries.empty?

        request = Gitaly::SetConfigRequest.new(repository: @gitaly_repo)
        entries.each do |key, value|
          request.entries << build_set_config_entry(key, value)
        end

        GitalyClient.call(
          @storage,
          :repository_service,
          :set_config,
          request,
          timeout: GitalyClient.fast_timeout
        )

        nil
      end

      def delete_config(keys)
        return if keys.empty?

        request = Gitaly::DeleteConfigRequest.new(repository: @gitaly_repo, keys: keys)

        GitalyClient.call(
          @storage,
          :repository_service,
          :delete_config,
          request,
          timeout: GitalyClient.fast_timeout
        )

        nil
      end

      def license_short_name
        request = Gitaly::FindLicenseRequest.new(repository: @gitaly_repo)

        response = GitalyClient.call(@storage, :repository_service, :find_license, request, timeout: GitalyClient.fast_timeout)

        response.license_short_name.presence
      end

      def calculate_checksum
        request  = Gitaly::CalculateChecksumRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@storage, :repository_service, :calculate_checksum, request, timeout: GitalyClient.fast_timeout)
        response.checksum.presence
      rescue GRPC::DataLoss => e
        raise Gitlab::Git::Repository::InvalidRepository, e
      end

      def raw_changes_between(from, to)
        request = Gitaly::GetRawChangesRequest.new(repository: @gitaly_repo, from_revision: from, to_revision: to)

        GitalyClient.call(@storage, :repository_service, :get_raw_changes, request, timeout: GitalyClient.fast_timeout)
      end

      def search_files_by_name(ref, query)
        request = Gitaly::SearchFilesByNameRequest.new(repository: @gitaly_repo, ref: ref, query: query)
        GitalyClient.call(@storage, :repository_service, :search_files_by_name, request, timeout: GitalyClient.fast_timeout).flat_map(&:files)
      end

      def search_files_by_content(ref, query, options = {})
        request = Gitaly::SearchFilesByContentRequest.new(repository: @gitaly_repo, ref: ref, query: query)
        response = GitalyClient.call(@storage, :repository_service, :search_files_by_content, request, timeout: GitalyClient.default_timeout)
        search_results_from_response(response, options)
      end

      def search_files_by_regexp(ref, filter)
        request = Gitaly::SearchFilesByNameRequest.new(repository: @gitaly_repo, ref: ref, query: '.', filter: filter)
        GitalyClient.call(@storage, :repository_service, :search_files_by_name, request, timeout: GitalyClient.fast_timeout).flat_map(&:files)
      end

      def disconnect_alternates
        request = Gitaly::DisconnectGitAlternatesRequest.new(
          repository: @gitaly_repo
        )

        GitalyClient.call(@storage, :object_pool_service, :disconnect_git_alternates, request, timeout: GitalyClient.long_timeout)
      end

      def rename(relative_path)
        request = Gitaly::RenameRepositoryRequest.new(repository: @gitaly_repo, relative_path: relative_path)

        GitalyClient.call(@storage, :repository_service, :rename_repository, request, timeout: GitalyClient.fast_timeout)
      end

      def remove
        request = Gitaly::RemoveRepositoryRequest.new(repository: @gitaly_repo)

        GitalyClient.call(@storage, :repository_service, :remove_repository, request, timeout: GitalyClient.long_timeout)
      end

      def replicate(source_repository)
        request = Gitaly::ReplicateRepositoryRequest.new(
          repository: @gitaly_repo,
          source: source_repository.gitaly_repository
        )

        GitalyClient.call(
          @storage,
          :repository_service,
          :replicate_repository,
          request,
          remote_storage: source_repository.storage,
          timeout: GitalyClient.long_timeout
        )
      end

      private

      def search_results_from_response(gitaly_response, options = {})
        limit = options[:limit]

        matches = []
        matches_count = 0
        current_match = +""

        gitaly_response.each do |message|
          next if message.nil?

          break if limit && matches_count >= limit

          current_match << message.match_data

          if message.end_of_match
            matches << current_match
            current_match = +""
            matches_count += 1
          end
        end

        matches
      end

      def gitaly_fetch_stream_to_file(save_path, rpc_name, request_class, timeout)
        request = request_class.new(repository: @gitaly_repo)
        response = GitalyClient.call(
          @storage,
          :repository_service,
          rpc_name,
          request,
          timeout: timeout
        )
        write_stream_to_file(response, save_path)
      end

      def write_stream_to_file(response, save_path)
        File.open(save_path, 'wb') do |f|
          response.each do |message|
            f.write(message.data)
          end
        end
        # If the file is empty means that we received an empty stream, we delete the file
        FileUtils.rm(save_path) if File.zero?(save_path)
      end

      def gitaly_repo_stream_request(file_path, rpc_name, request_class, timeout)
        request = request_class.new(repository: @gitaly_repo)
        enum = Enumerator.new do |y|
          File.open(file_path, 'rb') do |f|
            while data = f.read(MAX_MSG_SIZE)
              request.data = data

              y.yield request
              request = request_class.new
            end
          end
        end

        GitalyClient.call(
          @storage,
          :repository_service,
          rpc_name,
          enum,
          timeout: timeout
        )
      end

      def build_set_config_entry(key, value)
        entry = Gitaly::SetConfigRequest::Entry.new(key: key)

        case value
        when String
          entry.value_str = value
        when Integer
          entry.value_int32 = value
        when TrueClass, FalseClass
          entry.value_bool = value
        else
          raise InvalidArgument, "invalid git config value: #{value.inspect}"
        end

        entry
      end
    end
  end
end
