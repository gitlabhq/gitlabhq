# frozen_string_literal: true

class AddMetadataToZoektIndices < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    add_column :zoekt_indices, :metadata, :jsonb, default: {}, null: false
  end
end
