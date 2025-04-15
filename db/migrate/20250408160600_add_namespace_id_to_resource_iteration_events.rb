# frozen_string_literal: true

class AddNamespaceIdToResourceIterationEvents < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :resource_iteration_events, :namespace_id, :bigint, null: false, default: 0
  end
end
