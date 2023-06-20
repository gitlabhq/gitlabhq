# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # A job to remove `project_group_links` records whose associated group
    # does not exist in `namespaces` table anymore.
    class RemoveProjectGroupLinkWithMissingGroups < Gitlab::BackgroundMigration::BatchedMigrationJob
      scope_to ->(relation) { relation }
      operation_name :delete_all
      feature_category :groups_and_projects

      def perform
        each_sub_batch do |sub_batch|
          records = sub_batch.joins(
            "LEFT OUTER JOIN namespaces ON namespaces.id = project_group_links.group_id AND namespaces.type = 'Group'"
          ).where(namespaces: { id: nil })

          ids = records.map(&:id)

          next if ids.empty?

          Gitlab::AppLogger.info({ message: 'Removing project group link with non-existent groups',
                                  deleted_count: ids.count,
                                  ids:  ids })

          records.delete_all
        end
      end
    end
  end
end
