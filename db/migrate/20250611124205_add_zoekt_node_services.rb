# frozen_string_literal: true

class AddZoektNodeServices < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    add_column :zoekt_nodes, :services, :smallint, array: true, null: false, default: [0]
  end
end
