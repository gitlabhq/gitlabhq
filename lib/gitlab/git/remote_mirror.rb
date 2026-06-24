# frozen_string_literal: true

module Gitlab
  module Git
    class RemoteMirror
      include Gitlab::Git::WrapsGitalyErrors

      attr_reader :repository, :remote_url, :only_branches_matching, :ssh_key, :known_hosts, :keep_divergent_refs,
        :resolved_address

      def initialize(repository, remote_url, only_branches_matching: [], ssh_key: nil, known_hosts: nil, keep_divergent_refs: false, resolved_address: '')
        @repository = repository
        @remote_url = remote_url
        @only_branches_matching = only_branches_matching
        @ssh_key = ssh_key
        @known_hosts = known_hosts
        @keep_divergent_refs = keep_divergent_refs
        @resolved_address = resolved_address
      end

      def update
        wrapped_gitaly_errors do
          repository.gitaly_remote_client.update_remote_mirror(
            remote_url,
            only_branches_matching,
            ssh_key: ssh_key,
            known_hosts: known_hosts,
            keep_divergent_refs: keep_divergent_refs,
            resolved_address: resolved_address
          )
        end
      end
    end
  end
end
