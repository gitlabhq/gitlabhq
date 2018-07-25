module Gitlab
  module Git
    class RemoteMirror
      def initialize(repository, ref_name)
        @repository = repository
        @ref_name = ref_name
      end

      def update(only_branches_matching: [])
        @repository.wrapped_gitaly_errors do
          @repository.gitaly_remote_client.update_remote_mirror(@ref_name, only_branches_matching)
        end
      end
    end
  end
end
