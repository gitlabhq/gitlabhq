# frozen_string_literal: true

class RemoveNamespacePendingDeleteColumn < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def up
    remove_column :namespace_details, :pending_delete
  end

  def down
    add_column :namespace_details, :pending_delete, :boolean, default: false, null: false
  end
end
