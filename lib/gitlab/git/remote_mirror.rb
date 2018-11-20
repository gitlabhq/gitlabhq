# frozen_string_literal: true

module Gitlab
  module Git
    class RemoteMirror
      include Gitlab::Git::WrapsGitalyErrors

      attr_reader :repository, :ref_name, :only_branches_matching, :ssh_key, :known_hosts

      def initialize(repository, ref_name, only_branches_matching: [], ssh_key: nil, known_hosts: nil)
        @repository = repository
        @ref_name = ref_name
        @only_branches_matching = only_branches_matching
        @ssh_key = ssh_key
        @known_hosts = known_hosts
      end

      def update
        wrapped_gitaly_errors do
          repository.gitaly_remote_client.update_remote_mirror(
            ref_name,
            only_branches_matching,
            ssh_key: ssh_key,
            known_hosts: known_hosts
          )
        end
      end
    end
  end
end
