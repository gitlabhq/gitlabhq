# frozen_string_literal: true

class AddWorkItemTypesOldIdColumn < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    add_column :work_item_types, :old_id, :bigint
  end
end
