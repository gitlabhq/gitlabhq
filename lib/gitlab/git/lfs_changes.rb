module Gitlab
  module Git
    class LfsChanges
      def initialize(repository, newrev)
        @repository = repository
        @newrev = newrev
      end

      def new_pointers(object_limit: nil, not_in: nil)
        @repository.gitaly_blob_client.get_new_lfs_pointers(@newrev, object_limit, not_in)
      end

      def all_pointers
        @repository.gitaly_blob_client.get_all_lfs_pointers(@newrev)
      end
    end
  end
end
