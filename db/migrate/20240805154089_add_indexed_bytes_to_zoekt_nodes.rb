# frozen_string_literal: true

class AddIndexedBytesToZoektNodes < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :zoekt_nodes, :indexed_bytes, :bigint, default: 0, null: false
  end
end
