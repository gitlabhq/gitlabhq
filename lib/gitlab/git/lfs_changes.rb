module Gitlab
  module Git
    class LfsChanges
      def initialize(repository, newrev)
        @repository = repository
        @newrev = newrev
      end

      def new_pointers(object_limit: nil, not_in: nil)
        @new_pointers ||= begin
          object_ids = new_objects(not_in: not_in)
          object_ids = object_ids.take(object_limit) if object_limit

          Gitlab::Git::Blob.batch_lfs_pointers(@repository, object_ids)
        end
      end

      def all_pointers
        object_ids = rev_list.all_objects(require_path: true)

        Gitlab::Git::Blob.batch_lfs_pointers(@repository, object_ids)
      end

      private

      def new_objects(not_in:)
        rev_list.new_objects(require_path: true, lazy: true, not_in: not_in)
      end

      def rev_list
        ::Gitlab::Git::RevList.new(path_to_repo: @repository.path_to_repo,
                                   newrev: @newrev)
      end
    end
  end
end
