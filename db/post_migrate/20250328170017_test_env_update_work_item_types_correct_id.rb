# frozen_string_literal: true

class TestEnvUpdateWorkItemTypesCorrectId < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.11'

  def up
    # no-op
    # We don't need this migration in production environments, but because the test suite
    # maintains records in the `work_item_types` table, we need this migration to make sure migration specs
    # don't fail to rollback other migrations that create constraints on the table
  end

  def down
    # We no longer set a value for `correct_id` in the `work_item_types` table
    # so this migration is just needed to make sure existing records have a unique value for `correct_id`
    connection.execute(
      <<~SQL
        UPDATE work_item_types SET correct_id = id;
      SQL
    )
  end
end
