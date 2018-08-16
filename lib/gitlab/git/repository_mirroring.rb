module Gitlab
  module Git
    module RepositoryMirroring
      def remote_branches(remote_name)
        gitaly_ref_client.remote_branches(remote_name)
      end
    end
  end
end
