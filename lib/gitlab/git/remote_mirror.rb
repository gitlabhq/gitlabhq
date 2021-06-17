# frozen_string_literal: true

module Gitlab
  module Git
    class RemoteMirror
      include Gitlab::Git::WrapsGitalyErrors

      attr_reader :repository, :ref_name, :remote_url, :only_branches_matching, :ssh_key, :known_hosts, :keep_divergent_refs

      def initialize(repository, ref_name, remote_url, only_branches_matching: [], ssh_key: nil, known_hosts: nil, keep_divergent_refs: false)
        @repository = repository
        @ref_name = ref_name
        @remote_url = remote_url
        @only_branches_matching = only_branches_matching
        @ssh_key = ssh_key
        @known_hosts = known_hosts
        @keep_divergent_refs = keep_divergent_refs
      end

      def update
        wrapped_gitaly_errors do
          repository.gitaly_remote_client.update_remote_mirror(
            ref_name,
            remote_url,
            only_branches_matching,
            ssh_key: ssh_key,
            known_hosts: known_hosts,
            keep_divergent_refs: keep_divergent_refs
          )
        end
      end
    end
  end
end
