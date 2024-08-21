# frozen_string_literal: true

class UpdateHierarchyRestrictionSubepicsMaximumDepth < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.3'

  class MigrationWorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
  end

  class MigrationHierarchyRestriction < MigrationRecord
    self.table_name = 'work_item_hierarchy_restrictions'
  end

  NEW_DEPTH = 7
  OLD_DEPTH = 9

  def up
    upsert_epic_restrictions(max_depth: NEW_DEPTH)
  end

  def down
    upsert_epic_restrictions(max_depth: OLD_DEPTH)
  end

  private

  def upsert_epic_restrictions(max_depth: OLD_DEPTH)
    MigrationWorkItemType.reset_column_information

    epic_type = MigrationWorkItemType.find_by_name_and_namespace_id('Epic', nil)

    unless epic_type
      Gitlab::AppLogger.warn('Epic work item type not found, skipping hierarchy restrictions update')

      return
    end

    restrictions = [
      {
        parent_type_id: epic_type.id,
        child_type_id: epic_type.id,
        maximum_depth: max_depth,
        cross_hierarchy_enabled: true
      }
    ]

    MigrationHierarchyRestriction.reset_column_information
    MigrationHierarchyRestriction.upsert_all(
      restrictions,
      unique_by: :index_work_item_hierarchy_restrictions_on_parent_and_child
    )
  end
end
