# frozen_string_literal: true

class AddNamespaceIdToResourceStateEvents < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    add_column :resource_state_events, :namespace_id, :bigint, null: false, default: 0
  end
end
