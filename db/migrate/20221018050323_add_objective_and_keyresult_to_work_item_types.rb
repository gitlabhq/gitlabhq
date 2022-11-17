# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddObjectiveAndKeyresultToWorkItemTypes < Gitlab::Database::Migration[2.0]
  # Added the following statements as per https://docs.gitlab.com/ee/development/database/migrations_for_multiple_databases.html
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  OBJECTIVE_ENUM_VALUE = 5
  KEY_RESULT_ENUM_VALUE = 6

  class WorkItemType < MigrationRecord
    self.inheritance_column = :_type_disabled
    self.table_name = 'work_item_types'
  end

  def up
    # New instances will not run this migration and add this type via fixtures
    # checking if record exists mostly because migration specs will run all migrations
    # and that will conflict with the preloaded base work item types
    objective_work_item = WorkItemType.find_by(base_type: OBJECTIVE_ENUM_VALUE, name: 'Objective', namespace_id: nil)
    key_result_work_item = WorkItemType.find_by(base_type: KEY_RESULT_ENUM_VALUE, name: 'Key Result', namespace_id: nil)

    if objective_work_item
      say('Objective item record exist, skipping creation')
    else
      execute(
        <<~SQL
          INSERT INTO work_item_types (base_type, icon_name, name, created_at, updated_at) VALUES(
            #{OBJECTIVE_ENUM_VALUE}, 'issue-type-objective', 'Objective', NOW(), NOW()
            ) ON CONFLICT DO NOTHING;
        SQL
      )
    end

    if key_result_work_item
      say('Keyresult item record exist, skipping creation')
    else
      execute(
        <<~SQL
          INSERT INTO work_item_types (base_type, icon_name, name, created_at, updated_at) VALUES(
            #{KEY_RESULT_ENUM_VALUE}, 'issue-type-keyresult', 'Key Result', NOW(), NOW()
            ) ON CONFLICT DO NOTHING;
        SQL
      )
    end
  end

  def down
    # There's the remote possibility that issues could already be
    # using this issue type, with a tight foreign constraint.
    # Therefore we will not attempt to remove any data.
  end
end
