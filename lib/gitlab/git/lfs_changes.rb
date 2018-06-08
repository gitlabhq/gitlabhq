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
          rev_list.new_objects(rev_list_params(not_in: not_in)) do |object_ids|
            object_ids = object_ids.take(object_limit) if object_limit

            Gitlab::Git::Blob.batch_lfs_pointers(@repository, object_ids)
          end
        end
      end

      def git_all_pointers
        params = {}
        if rev_list_supports_new_options?
          params[:options] = ["--filter=blob:limit=#{Gitlab::Git::Blob::LFS_POINTER_MAX_SIZE}"]
        end

        rev_list.all_objects(rev_list_params(params)) do |object_ids|
          Gitlab::Git::Blob.batch_lfs_pointers(@repository, object_ids)
        end
      end

      def rev_list
        Gitlab::Git::RevList.new(@repository, newrev: @newrev)
      end

      # We're passing the `--in-commit-order` arg to ensure we don't wait
      # for git to traverse all commits before returning pointers.
      # This is required in order to improve the performance of LFS integrity check
      def rev_list_params(params = {})
        params[:options] ||= []
        params[:options] << "--in-commit-order" if rev_list_supports_new_options?
        params[:require_path] = true

        params
      end

      def rev_list_supports_new_options?
        return @option_supported if defined?(@option_supported)

        @option_supported = Gitlab::Git.version >= Gitlab::VersionInfo.parse('2.16.0')
      end
    end
  end
end
