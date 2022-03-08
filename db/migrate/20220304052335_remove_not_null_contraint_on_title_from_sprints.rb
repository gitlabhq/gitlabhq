# frozen_string_literal: true

class RemoveNotNullContraintOnTitleFromSprints < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    change_column_null :sprints, :title, true
  end

  def down
    execute <<~SQL
      UPDATE sprints SET title = id WHERE title IS NULL
    SQL

    change_column_null :sprints, :title, false
  end
end
