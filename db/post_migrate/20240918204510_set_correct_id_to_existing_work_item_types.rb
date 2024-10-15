# frozen_string_literal: true

class SetCorrectIdToExistingWorkItemTypes < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.5'

  WORK_ITEM_TYPES = {
    issue: { correct_id: 1, enum_value: 0 },
    incident: { correct_id: 2, enum_value: 1 },
    test_case: { correct_id: 3, enum_value: 2 },
    requirement: { correct_id: 4, enum_value: 3 },
    task: { correct_id: 5, enum_value: 4 },
    objective: { correct_id: 6, enum_value: 5 },
    key_result: { correct_id: 7, enum_value: 6 },
    epic: { correct_id: 8, enum_value: 7 },
    ticket: { correct_id: 9, enum_value: 8 }
  }.freeze

  class MigrationWorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
  end

  def up
    MigrationWorkItemType.reset_column_information

    WORK_ITEM_TYPES.each_value do |type_data|
      MigrationWorkItemType.where(base_type: type_data[:enum_value]).update_all(correct_id: type_data[:correct_id])
    end
  end

  def down
    MigrationWorkItemType.reset_column_information

    # Column is NOT NULL DEFAULT 0, so setting back to default
    MigrationWorkItemType.update_all(correct_id: 0)
  end
end
