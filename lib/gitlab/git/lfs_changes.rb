module Gitlab
  module Git
    class LfsChanges
      def initialize(repository, newrev)
        @repository = repository
        @newrev = newrev
      end

      def new_pointers(object_limit: nil, not_in: nil)
        @repository.gitaly_migrate(:blob_get_new_lfs_pointers) do |is_enabled|
          if is_enabled
            @repository.gitaly_blob_client.get_new_lfs_pointers(@newrev, object_limit, not_in)
          else
            git_new_pointers(object_limit, not_in)
          end
        end
      end

      def all_pointers
        @repository.gitaly_migrate(:blob_get_all_lfs_pointers) do |is_enabled|
          if is_enabled
            @repository.gitaly_blob_client.get_all_lfs_pointers(@newrev)
          else
            git_all_pointers
          end
        end
      end

      private

      def git_new_pointers(object_limit, not_in)
        @new_pointers ||= begin
          rev_list.new_objects(not_in: not_in, require_path: true) do |object_ids|
            object_ids = object_ids.take(object_limit) if object_limit

            Gitlab::Git::Blob.batch_lfs_pointers(@repository, object_ids)
          end
        end
      end

      def git_all_pointers
        rev_list.all_objects(require_path: true) do |object_ids|
          Gitlab::Git::Blob.batch_lfs_pointers(@repository, object_ids)
        end
      end

      def rev_list
        Gitlab::Git::RevList.new(@repository, newrev: @newrev)
      end
    end
  end
end
