# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class RepositoryService
      include Gitlab::EncodingHelper
      include WithFeatureFlagActors

      MAX_MSG_SIZE = 128.kilobytes

      def initialize(repository)
        @repository = repository
        @gitaly_repo = repository.gitaly_repository
        @storage = repository.storage

        self.repository_actor = repository
      end

      def exists?
        request = Gitaly::RepositoryExistsRequest.new(repository: @gitaly_repo)

        response = gitaly_client_call(@storage, :repository_service, :repository_exists, request, timeout: GitalyClient.fast_timeout)

        response.exists
      end

      # Optimize the repository. By default, this will perform heuristical housekeeping in the repository, which
      # is the recommended approach and will only optimize what needs to be optimized. If `eager = true`, then
      # Gitaly will instead be asked to perform eager housekeeping. As a consequence the housekeeping run will take a
      # _lot_ longer. It is not recommended to use eager housekeeping in general, but only in situations where it is
      # explicitly required.
      def optimize_repository(eager: false)
        strategy = if eager
                     Gitaly::OptimizeRepositoryRequest::Strategy::STRATEGY_EAGER
                   else
                     Gitaly::OptimizeRepositoryRequest::Strategy::STRATEGY_HEURISTICAL
                   end

        request = Gitaly::OptimizeRepositoryRequest.new(repository: @gitaly_repo,
          strategy: strategy)
        gitaly_client_call(@storage, :repository_service, :optimize_repository, request, timeout: GitalyClient.long_timeout)
      end

      def prune_unreachable_objects
        request = Gitaly::PruneUnreachableObjectsRequest.new(repository: @gitaly_repo)
        gitaly_client_call(@storage, :repository_service, :prune_unreachable_objects, request, timeout: GitalyClient.long_timeout)
      end

      def repository_size
        request = Gitaly::RepositorySizeRequest.new(repository: @gitaly_repo)
        response = gitaly_client_call(@storage, :repository_service, :repository_size, request, timeout: GitalyClient.long_timeout)
        response.size
      end

      def repository_info
        request = Gitaly::RepositoryInfoRequest.new(repository: @gitaly_repo)

        gitaly_client_call(@storage, :repository_service, :repository_info, request, timeout: GitalyClient.long_timeout)
      end

      def get_object_directory_size
        request = Gitaly::GetObjectDirectorySizeRequest.new(repository: @gitaly_repo)
        response = gitaly_client_call(@storage, :repository_service, :get_object_directory_size, request, timeout: GitalyClient.medium_timeout)

        response.size
      end

      def info_attributes
        request = Gitaly::GetInfoAttributesRequest.new(repository: @gitaly_repo)

        response = gitaly_client_call(@storage, :repository_service, :get_info_attributes, request, timeout: GitalyClient.fast_timeout)
        response.each_with_object([]) do |message, attributes|
          attributes << message.attributes
        end.join
      end

      # rubocop: disable Metrics/ParameterLists
      # The `remote` parameter is going away soonish anyway, at which point the
      # Rubocop warning can be enabled again.
      def fetch_remote(url, refmap:, ssh_auth:, forced:, no_tags:, timeout:, prune: true, check_tags_changed: false, http_authorization_header: "", resolved_address: "")
        request = Gitaly::FetchRemoteRequest.new(
          repository: @gitaly_repo,
          force: forced,
          no_tags: no_tags,
          timeout: timeout,
          no_prune: !prune,
          check_tags_changed: check_tags_changed,
          remote_params: Gitaly::Remote.new(
            url: url,
            mirror_refmaps: Array.wrap(refmap).map(&:to_s),
            http_authorization_header: http_authorization_header,
            resolved_address: resolved_address
          )
        )

        if ssh_auth&.ssh_mirror_url?
          if ssh_auth.ssh_key_auth? && ssh_auth.ssh_private_key.present?
            request.ssh_key = ssh_auth.ssh_private_key
          end

          if ssh_auth.ssh_known_hosts.present?
            request.known_hosts = ssh_auth.ssh_known_hosts
          end
        end

        gitaly_client_call(@storage, :repository_service, :fetch_remote, request, timeout: GitalyClient.long_timeout)
      end
      # rubocop: enable Metrics/ParameterLists

      def create_repository(default_branch = nil, object_format: nil)
        request = Gitaly::CreateRepositoryRequest.new(repository: @gitaly_repo, default_branch: encode_binary(default_branch), object_format: gitaly_object_format(object_format))
        gitaly_client_call(@storage, :repository_service, :create_repository, request, timeout: GitalyClient.fast_timeout)
      end

      def has_local_branches?
        request = Gitaly::HasLocalBranchesRequest.new(repository: @gitaly_repo)
        response = gitaly_client_call(@storage, :repository_service, :has_local_branches, request, timeout: GitalyClient.fast_timeout)

        response.value
      end

      def find_merge_base(*revisions)
        request = Gitaly::FindMergeBaseRequest.new(
          repository: @gitaly_repo,
          revisions: revisions.map { |r| encode_binary(r) }
        )

        response = gitaly_client_call(@storage, :repository_service, :find_merge_base, request, timeout: GitalyClient.fast_timeout)
        response.base.presence
      end

      def fork_repository(source_repository, branch = nil)
        revision = branch.present? ? "refs/heads/#{branch}" : ""

        request = Gitaly::CreateForkRequest.new(
          repository: @gitaly_repo,
          source_repository: source_repository.gitaly_repository,
          revision: revision
        )

        gitaly_client_call(
          @storage,
          :repository_service,
          :create_fork,
          request,
          remote_storage: source_repository.storage,
          timeout: GitalyClient.long_timeout
        )
      end

      def import_repository(source, http_authorization_header: '', mirror: false, resolved_address: '')
        request = Gitaly::CreateRepositoryFromURLRequest.new(
          repository: @gitaly_repo,
          url: source,
          http_authorization_header: http_authorization_header,
          mirror: mirror,
          resolved_address: resolved_address
        )

        gitaly_client_call(
          @storage,
          :repository_service,
          :create_repository_from_url,
          request,
          timeout: GitalyClient.long_timeout
        )
      end

      def fetch_source_branch(source_repository, source_branch, local_ref)
        request = Gitaly::FetchSourceBranchRequest.new(
          repository: @gitaly_repo,
          source_repository: source_repository.gitaly_repository,
          source_branch: source_branch.b,
          target_ref: local_ref.b
        )

        response = gitaly_client_call(
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
        response = gitaly_client_call(@storage, :repository_service, :fsck, request, timeout: GitalyClient.long_timeout)

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

      def create_from_bundle(bundle_path)
        gitaly_repo_stream_request(
          bundle_path,
          :create_repository_from_bundle,
          Gitaly::CreateRepositoryFromBundleRequest,
          GitalyClient.long_timeout
        )
      end

      def write_ref(ref_path, ref, old_ref)
        request = Gitaly::WriteRefRequest.new(
          repository: @gitaly_repo,
          ref: ref_path.b,
          revision: ref.b
        )
        request.old_revision = old_ref.b unless old_ref.nil?

        gitaly_client_call(@storage, :repository_service, :write_ref, request, timeout: GitalyClient.fast_timeout)
      end

      def find_license
        request = Gitaly::FindLicenseRequest.new(repository: @gitaly_repo)

        gitaly_client_call(@storage, :repository_service, :find_license, request, timeout: GitalyClient.medium_timeout)
      end

      def calculate_checksum
        request  = Gitaly::CalculateChecksumRequest.new(repository: @gitaly_repo)
        response = gitaly_client_call(@storage, :repository_service, :calculate_checksum, request, timeout: GitalyClient.fast_timeout)
        response.checksum.presence
      rescue GRPC::DataLoss => e
        raise Gitlab::Git::Repository::InvalidRepository, e
      end

      def raw_changes_between(from, to)
        request = Gitaly::GetRawChangesRequest.new(repository: @gitaly_repo, from_revision: from, to_revision: to)

        gitaly_client_call(@storage, :repository_service, :get_raw_changes, request, timeout: GitalyClient.fast_timeout)
      end

      def search_files_by_name(ref, query, limit: 0, offset: 0)
        request = Gitaly::SearchFilesByNameRequest.new(repository: @gitaly_repo, ref: encode_binary(ref), query: query, limit: limit, offset: offset)
        gitaly_client_call(@storage, :repository_service, :search_files_by_name, request, timeout: GitalyClient.fast_timeout).flat_map(&:files)
      end

      def search_files_by_content(ref, query, options = {})
        request = Gitaly::SearchFilesByContentRequest.new(repository: @gitaly_repo, ref: encode_binary(ref), query: query)
        response = gitaly_client_call(@storage, :repository_service, :search_files_by_content, request, timeout: GitalyClient.default_timeout)
        search_results_from_response(response, options)
      end

      def search_files_by_regexp(ref, filter, limit: 0, offset: 0)
        request = Gitaly::SearchFilesByNameRequest.new(repository: @gitaly_repo, ref: encode_binary(ref), query: '.', filter: filter, limit: limit, offset: offset)
        gitaly_client_call(@storage, :repository_service, :search_files_by_name, request, timeout: GitalyClient.fast_timeout).flat_map(&:files)
      end

      def disconnect_alternates
        request = Gitaly::DisconnectGitAlternatesRequest.new(
          repository: @gitaly_repo
        )

        gitaly_client_call(@storage, :object_pool_service, :disconnect_git_alternates, request, timeout: GitalyClient.long_timeout)
      end

      def remove
        request = Gitaly::RemoveRepositoryRequest.new(repository: @gitaly_repo)

        gitaly_client_call(@storage, :repository_service, :remove_repository, request, timeout: GitalyClient.long_timeout)
      end

      def replicate(source_repository, partition_hint: "")
        request = Gitaly::ReplicateRepositoryRequest.new(
          repository: @gitaly_repo,
          source: source_repository.gitaly_repository
        )

        gitaly_client_call(
          @storage,
          :repository_service,
          :replicate_repository,
          request,
          remote_storage: source_repository.storage,
          timeout: GitalyClient.long_timeout
        ) do |kwargs|
          kwargs.deep_merge(metadata: { 'gitaly-partitioning-hint': partition_hint })
        end
      end

      def object_pool
        request = Gitaly::GetObjectPoolRequest.new(repository: @gitaly_repo)

        gitaly_client_call(
          @storage,
          :object_pool_service,
          :get_object_pool,
          request,
          timeout: GitalyClient.medium_timeout
        )
      end

      def get_file_attributes(revision, paths, attributes)
        request = Gitaly::GetFileAttributesRequest
          .new(repository: @gitaly_repo, revision: revision, paths: paths, attributes: attributes)

        gitaly_client_call(@repository.storage, :repository_service, :get_file_attributes, request, timeout: GitalyClient.fast_timeout)
      end

      def object_format
        request = Gitaly::ObjectFormatRequest.new(repository: @gitaly_repo)

        gitaly_client_call(@storage, :repository_service, :object_format, request, timeout: GitalyClient.fast_timeout)
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

          next unless message.end_of_match

          matches << current_match
          current_match = +""
          matches_count += 1
        end

        matches
      end

      def gitaly_fetch_stream_to_file(save_path, rpc_name, request_class, timeout)
        request = request_class.new(repository: @gitaly_repo)
        response = gitaly_client_call(
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

        gitaly_client_call(
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

      def gitaly_object_format(format)
        case format
        when Repository::FORMAT_SHA1
          Gitaly::ObjectFormat::OBJECT_FORMAT_SHA1
        when Repository::FORMAT_SHA256
          Gitaly::ObjectFormat::OBJECT_FORMAT_SHA256
        end
      end
    end
  end
end
