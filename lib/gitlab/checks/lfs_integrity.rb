module Gitlab
  module Checks
    class LfsIntegrity
      REV_LIST_OBJECT_LIMIT = 2_000

      def initialize(project, newrev)
        @project = project
        @newrev = newrev
      end

      def objects_missing?
        return false unless @newrev && @project.lfs_enabled?

        new_lfs_pointers = Gitlab::Git::LfsChanges.new(@project.repository, @newrev).new_pointers(object_limit: REV_LIST_OBJECT_LIMIT)

        return false unless new_lfs_pointers.present?

        existing_count = @project.lfs_storage_project
                                 .lfs_objects
                                 .where(oid: new_lfs_pointers.map(&:lfs_oid))
                                 .count

        existing_count != new_lfs_pointers.count
      end
    end
  end
end
