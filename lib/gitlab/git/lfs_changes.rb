module Gitlab
  module Git
    class LfsChanges
      LFS_PATTERN_REGEX = /^(.*)\sfilter=lfs\sdiff=lfs\smerge=lfs/.freeze
      LFS_ATTRIBUTES_FILE = '.gitattributes'.freeze

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
        # @repository.gitaly_migrate(:blob_get_all_lfs_pointers) do |is_enabled|
        #   if is_enabled
        #     @repository.gitaly_blob_client.get_all_lfs_pointers(@newrev)
        #   else
            git_all_pointers
        #   end
        # end
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
        lfs_patterns = get_lfs_track_patterns

        rev_list.all_objects(only_files: lfs_patterns, require_path: true) do |object_ids|
          Gitlab::Git::Blob.batch_lfs_pointers(@repository, object_ids)
        end
      end

      def get_lfs_track_patterns
        rev_list.all_objects(only_files: [LFS_ATTRIBUTES_FILE], require_path: true) do |object_ids|
          object_ids.map! do |object_id|
            blob = Gitlab::Git::Blob.raw(@repository, object_id)
            if result = blob.data.match(LFS_PATTERN_REGEX)
              result[1]
            end
          end.reject(&:blank?)
        end
      end

      def rev_list
        Gitlab::Git::RevList.new(@repository, newrev: @newrev)
      end
    end
  end
end
