# frozen_string_literal: true

class ChangeEpicsHierarchyRestrictions < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class MigrationWorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
  end

  class MigrationHierarchyRestriction < MigrationRecord
    self.table_name = 'work_item_hierarchy_restrictions'
  end

  def up
    upsert_epic_restrictions
  end

  def down
    upsert_epic_restrictions(stepping_down: true)
  end

  private

  def upsert_epic_restrictions(stepping_down: false)
    issue_type = MigrationWorkItemType.find_by_name_and_namespace_id('Issue', nil)
    epic_type = MigrationWorkItemType.find_by_name_and_namespace_id('Epic', nil)

    unless issue_type && epic_type
      Gitlab::AppLogger.warn('Issue or Epic work item types not found, skipping hierarchy restrictions update')

      return
    end

    restrictions = [
      {
        parent_type_id: epic_type.id,
        child_type_id: epic_type.id,
        maximum_depth: 9,
        cross_hierarchy_enabled: !stepping_down
      },
      {
        parent_type_id: epic_type.id,
        child_type_id: issue_type.id,
        maximum_depth: 1,
        cross_hierarchy_enabled: !stepping_down
      }
    ]

    MigrationHierarchyRestriction.reset_column_information
    MigrationHierarchyRestriction.upsert_all(
      restrictions,
      unique_by: :index_work_item_hierarchy_restrictions_on_parent_and_child
    )
  end
end
