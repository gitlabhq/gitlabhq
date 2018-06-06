module Gitlab
  module Checks
    class LfsIntegrity
      def initialize(project, oldrev, newrev)
        @project = project
        @oldrev = oldrev
        @newrev = newrev
      end

      def objects_missing?
        return false unless @newrev && @project.lfs_enabled?

        new_lfs_pointers = Gitlab::Git::Blob.lfs_pointers_between(@project.repository, @oldrev, @newrev)

        return false unless new_lfs_pointers.present?

        existing_count = @project.all_lfs_objects
                                 .where(oid: new_lfs_pointers.map(&:lfs_oid))
                                 .count

        existing_count != new_lfs_pointers.count
      end
    end
  end
end
