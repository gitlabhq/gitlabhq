module Gitlab
  module Checks
    class LfsIntegrity
      def initialize(project, newrev)
        @project = project
        @newrev = newrev
      end

      def objects_missing?
        return false unless @newrev && @project.lfs_enabled?

        new_lfs_pointers = Gitlab::Git::LfsChanges.new(@project.repository, @newrev)
                                                  .new_pointers(object_limit: ::Gitlab::Git::Repository::REV_LIST_COMMIT_LIMIT)

        return false unless new_lfs_pointers.present?

        existing_count = @project.all_lfs_objects
                                 .where(oid: new_lfs_pointers.map(&:lfs_oid))
                                 .count

        existing_count != new_lfs_pointers.count
      end
    end
  end
end
