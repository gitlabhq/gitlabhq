# frozen_string_literal: true

module Gitlab
  module Checks
    class LfsIntegrity
      def initialize(project, newrevs, time_left)
        @project = project
        @newrevs = newrevs
        @time_left = time_left
      end

      def objects_missing?
        return false unless @project.lfs_enabled?

        newrevs = @newrevs.reject { |rev| rev.blank? || Gitlab::Git.blank_ref?(rev) }
        return if newrevs.blank?

        new_lfs_pointers = Gitlab::Git::LfsChanges.new(@project.repository, newrevs)
                                                  .new_pointers(object_limit: ::Gitlab::Git::Repository::REV_LIST_COMMIT_LIMIT, dynamic_timeout: @time_left)

        return false unless new_lfs_pointers.present?

        existing_count = @project.lfs_objects
                                 .for_oids(new_lfs_pointers.map(&:lfs_oid))
                                 .count

        existing_count != new_lfs_pointers.count
      end
    end
  end
end
