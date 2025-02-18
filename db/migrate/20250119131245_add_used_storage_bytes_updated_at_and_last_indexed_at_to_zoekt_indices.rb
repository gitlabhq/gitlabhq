# frozen_string_literal: true

class AddUsedStorageBytesUpdatedAtAndLastIndexedAtToZoektIndices < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  TABLE_NAME = 'zoekt_indices'

  def change
    add_column TABLE_NAME, :used_storage_bytes_updated_at, :datetime_with_timezone, default: '1970-01-01', null: false
    add_column TABLE_NAME, :last_indexed_at, :datetime_with_timezone, default: '1970-01-01', null: false
  end
end
