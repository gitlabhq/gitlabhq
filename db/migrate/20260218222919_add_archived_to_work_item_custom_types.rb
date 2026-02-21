# frozen_string_literal: true

class AddArchivedToWorkItemCustomTypes < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def up
    add_column :work_item_custom_types, :archived, :boolean, default: false, null: false
  end

  def down
    remove_column :work_item_custom_types, :archived
  end
end
