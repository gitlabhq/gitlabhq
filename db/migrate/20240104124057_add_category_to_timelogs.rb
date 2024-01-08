# frozen_string_literal: true

class AddCategoryToTimelogs < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.8'

  def up
    add_column :timelogs, :timelog_category_id, :bigint
    add_concurrent_index(:timelogs, :timelog_category_id)
    add_concurrent_foreign_key(
      :timelogs,
      :timelog_categories,
      column: :timelog_category_id,
      on_delete: :nullify
    )
  end

  def down
    remove_column :timelogs, :timelog_category_id
  end
end
