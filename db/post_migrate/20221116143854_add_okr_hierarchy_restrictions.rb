# frozen_string_literal: true

class AddOkrHierarchyRestrictions < Gitlab::Database::Migration[2.0]
  class WorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
  end

  class HierarchyRestriction < MigrationRecord
    self.table_name = 'work_item_hierarchy_restrictions'
  end

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  def up
    objective = WorkItemType.find_by_name_and_namespace_id('Objective', nil)
    key_result = WorkItemType.find_by_name_and_namespace_id('Key Result', nil)
    issue = WorkItemType.find_by_name_and_namespace_id('Issue', nil)
    task = WorkItemType.find_by_name_and_namespace_id('Task', nil)
    incident = WorkItemType.find_by_name_and_namespace_id('Incident', nil)

    # work item default types should be filled, if this is not the case
    # then restrictions will be created together with work item types
    unless objective && key_result && issue && task && incident
      Gitlab::AppLogger.warn('default types are missing, not adding restrictions')

      return
    end

    restrictions = [
      { parent_type_id: objective.id, child_type_id: objective.id, maximum_depth: 9 },
      { parent_type_id: objective.id, child_type_id: key_result.id, maximum_depth: 1 },
      { parent_type_id: issue.id, child_type_id: task.id, maximum_depth: 1 },
      { parent_type_id: incident.id, child_type_id: task.id, maximum_depth: 1 }
    ]

    HierarchyRestriction.upsert_all(
      restrictions,
      unique_by: :index_work_item_hierarchy_restrictions_on_parent_and_child
    )
  end

  def down
    # so far restrictions table was empty so we can delete all records when
    # migrating down
    HierarchyRestriction.delete_all
  end
end
