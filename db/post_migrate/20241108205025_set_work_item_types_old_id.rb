# frozen_string_literal: true

class SetWorkItemTypesOldId < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.6'

  def up
    connection.execute(
      <<~SQL
        UPDATE work_item_types SET old_id = id;
      SQL
    )
  end

  def down
    connection.execute(
      <<~SQL
        UPDATE work_item_types SET old_id = NULL;
      SQL
    )
  end
end
