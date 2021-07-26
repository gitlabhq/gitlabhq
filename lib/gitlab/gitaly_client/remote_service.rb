# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class RemoteService
      include Gitlab::EncodingHelper

      MAX_MSG_SIZE = 128.kilobytes.freeze

      def self.exists?(remote_url)
        storage = GitalyClient.random_storage

        request = Gitaly::FindRemoteRepositoryRequest.new(remote: remote_url, storage_name: storage)

        response = GitalyClient.call(storage,
                                     :remote_service,
                                     :find_remote_repository, request,
                                     timeout: GitalyClient.medium_timeout)

        response.exists
      end

      def initialize(repository)
        @repository = repository
        @gitaly_repo = repository.gitaly_repository
        @storage = repository.storage
      end

      # The remote_name parameter is deprecated and will be removed soon.
      def find_remote_root_ref(remote_name, remote_url, authorization)
        request = Gitaly::FindRemoteRootRefRequest.new(repository: @gitaly_repo,
                                                       remote_url: remote_url,
                                                       http_authorization_header: authorization)

        response = GitalyClient.call(@storage, :remote_service,
                                     :find_remote_root_ref, request, timeout: GitalyClient.medium_timeout)

        encode_utf8(response.ref)
      end

      def update_remote_mirror(ref_name, remote_url, only_branches_matching, ssh_key: nil, known_hosts: nil, keep_divergent_refs: false)
        req_enum = Enumerator.new do |y|
          first_request = Gitaly::UpdateRemoteMirrorRequest.new(
            repository: @gitaly_repo
          )

          if remote_url
            first_request.remote = Gitaly::UpdateRemoteMirrorRequest::Remote.new(url: remote_url)
          else
            first_request.ref_name = ref_name
          end

          first_request.ssh_key = ssh_key if ssh_key.present?
          first_request.known_hosts = known_hosts if known_hosts.present?
          first_request.keep_divergent_refs = keep_divergent_refs

          y.yield(first_request)

          current_size = 0

          slices = only_branches_matching.slice_before do |branch_name|
            current_size += branch_name.bytesize

            next false if current_size < MAX_MSG_SIZE

            current_size = 0
          end

          slices.each do |slice|
            y.yield Gitaly::UpdateRemoteMirrorRequest.new(only_branches_matching: slice)
          end
        end

        GitalyClient.call(@storage, :remote_service, :update_remote_mirror, req_enum, timeout: GitalyClient.long_timeout)
      end
    end
  end
end
