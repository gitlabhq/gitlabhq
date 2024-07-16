# frozen_string_literal: true

class AddPendingDeleteToNamespaceDetails < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :namespace_details, :pending_delete, :boolean, default: false, null: false
  end
end
