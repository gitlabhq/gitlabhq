# frozen_string_literal: true

class EnableCrossHierarchyForHierarchyRestrictions < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.1'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class MigrationWorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
  end

  class MigrationHierarchyRestriction < MigrationRecord
    self.table_name = 'work_item_hierarchy_restrictions'
  end

  def up
    upsert_enable_cross_hierarchy_restrictions
  end

  def down
    upsert_enable_cross_hierarchy_restrictions(stepping_down: true)
  end

  private

  def upsert_enable_cross_hierarchy_restrictions(stepping_down: false)
    MigrationWorkItemType.reset_column_information

    issue_type = MigrationWorkItemType.find_by_name_and_namespace_id('Issue', nil)
    task_type = MigrationWorkItemType.find_by_name_and_namespace_id('Task', nil)
    objective_type = MigrationWorkItemType.find_by_name_and_namespace_id('Objective', nil)
    key_result_type = MigrationWorkItemType.find_by_name_and_namespace_id('Key Result', nil)
    incident_type = MigrationWorkItemType.find_by_name_and_namespace_id('Incident', nil)
    ticket_type = MigrationWorkItemType.find_by_name_and_namespace_id('Ticket', nil)

    unless issue_type && task_type && objective_type && key_result_type && incident_type && ticket_type
      Gitlab::AppLogger.warn(
        'One of Issue, Task, Objective, Key Result, Incident, Ticket work item types not found, ' \
          'skipping hierarchy restrictions update'
      )

      return
    end

    restrictions = [
      {
        parent_type_id: objective_type.id,
        child_type_id: objective_type.id,
        maximum_depth: 9,
        cross_hierarchy_enabled: !stepping_down
      },
      {
        parent_type_id: objective_type.id,
        child_type_id: key_result_type.id,
        maximum_depth: 1,
        cross_hierarchy_enabled: !stepping_down
      },
      {
        parent_type_id: issue_type.id,
        child_type_id: task_type.id,
        maximum_depth: 1,
        cross_hierarchy_enabled: !stepping_down
      },
      {
        parent_type_id: incident_type.id,
        child_type_id: task_type.id,
        maximum_depth: 1,
        cross_hierarchy_enabled: !stepping_down
      },
      {
        parent_type_id: ticket_type.id,
        child_type_id: task_type.id,
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
