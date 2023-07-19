# frozen_string_literal: true

class AddStateToCatalogResources < Gitlab::Database::Migration[2.1]
  DRAFT = 0

  def change
    add_column :catalog_resources, :state, :smallint, null: false, limit: 1, default: DRAFT
  end
end
