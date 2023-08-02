# frozen_string_literal: true

class AddEpicWorkItemType < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  ISSUE_ENUM_VALUE = 0
  EPIC_ENUM_VALUE = 7
  EPIC_NAME = 'Epic'
  EPIC_WIDGETS = {
    'Assignees' => 0,
    'Description' => 1,
    'Hierarchy' => 2,
    'Labels' => 3,
    'Notes' => 5,
    'Start and due date' => 6,
    'Health status' => 7,
    'Status' => 11,
    'Notifications' => 14,
    'Award emoji' => 16
  }.freeze

  class MigrationWorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
  end

  class MigrationWidgetDefinition < MigrationRecord
    self.table_name = 'work_item_widget_definitions'
  end

  class MigrationHierarchyRestriction < MigrationRecord
    self.table_name = 'work_item_hierarchy_restrictions'
  end

  def up
    # New instances will not run this migration and add this type via fixtures
    # checking if record exists mostly because migration specs will run all migrations
    # and that will conflict with the preloaded base work item types
    existing_epic_work_item_type = MigrationWorkItemType.find_by(base_type: EPIC_ENUM_VALUE, namespace_id: nil)

    return say('Epic work item type record exists, skipping creation') if existing_epic_work_item_type

    new_epic_work_item_type = MigrationWorkItemType.create(
      name: EPIC_NAME,
      namespace_id: nil,
      base_type: EPIC_ENUM_VALUE,
      icon_name: 'issue-type-epic'
    )

    widgets = EPIC_WIDGETS.map do |widget_name, widget_enum_value|
      {
        work_item_type_id: new_epic_work_item_type.id,
        name: widget_name,
        widget_type: widget_enum_value
      }
    end

    MigrationWidgetDefinition.upsert_all(
      widgets,
      unique_by: :index_work_item_widget_definitions_on_default_witype_and_name
    )

    issue_type = MigrationWorkItemType.find_by(base_type: ISSUE_ENUM_VALUE, namespace_id: nil)
    return say('Issue work item type not found, skipping hierarchy restrictions creation') unless issue_type

    restrictions = [
      { parent_type_id: new_epic_work_item_type.id, child_type_id: new_epic_work_item_type.id, maximum_depth: 9 },
      { parent_type_id: new_epic_work_item_type.id, child_type_id: issue_type.id, maximum_depth: 1 }
    ]

    MigrationHierarchyRestriction.upsert_all(
      restrictions,
      unique_by: :index_work_item_hierarchy_restrictions_on_parent_and_child
    )
  end

  def down
    # There's the remote possibility that issues could already be
    # using this issue type, with a tight foreign constraint.
    # Therefore we will not attempt to remove any data.
  end
end
