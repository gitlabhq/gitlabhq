# frozen_string_literal: true

class SetDefaultReservedStorageBytes < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def up
    change_column_default :zoekt_indices, :reserved_storage_bytes, from: nil, to: 10.gigabytes
  end

  def down
    change_column_default :zoekt_indices, :reserved_storage_bytes, from: 10.gigabytes, to: nil
  end
end
