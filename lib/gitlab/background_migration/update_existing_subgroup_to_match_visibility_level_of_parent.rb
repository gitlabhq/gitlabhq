# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This background migration updates children of group to match visibility of a parent
    class UpdateExistingSubgroupToMatchVisibilityLevelOfParent
      def perform(parents_groups_ids, level)
        groups_ids = Gitlab::ObjectHierarchy.new(Group.where(id: parents_groups_ids))
          .base_and_descendants
          .where("visibility_level > ?", level)
          .select(:id)

        return if groups_ids.empty?

        Group
          .where(id: groups_ids)
          .update_all(visibility_level: level)
      end
    end
  end
end
