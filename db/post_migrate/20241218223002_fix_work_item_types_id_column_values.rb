# frozen_string_literal: true

class FixWorkItemTypesIdColumnValues < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.8'

  def up
    connection.execute(
      <<~SQL
        UPDATE work_item_types SET id = correct_id;
      SQL
    )
  end

  def down
    # For newer instances, old_id might be null as those instances did not go through the id cleanup process.
    # These instances were created with all the records in the work_item_types table already in the correct state.
    # So, running the migration would leave the records in the same state that they already had.
    # correct_id was already eaqual to id in every record.
    connection.execute(
      <<~SQL
        UPDATE work_item_types SET id = old_id WHERE old_id IS NOT NULL;
      SQL
    )
  end
end
