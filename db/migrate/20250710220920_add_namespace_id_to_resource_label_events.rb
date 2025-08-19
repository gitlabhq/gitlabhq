# frozen_string_literal: true

class AddNamespaceIdToResourceLabelEvents < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    add_column :resource_label_events, :namespace_id, :bigint, null: false, default: 0 # rubocop:disable Migration/PreventAddingColumns -- Sharding key is an exception
  end
end
