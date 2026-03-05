# frozen_string_literal: true

class ChangeSizeToBigintOnVirtualRegistriesContainerCacheRemoteEntries < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!

  TABLE = :virtual_registries_container_cache_remote_entries
  COLUMN = :size

  def up
    change_column_type_concurrently TABLE, COLUMN, :bigint, batch_column_name: :iid
  end

  def down
    undo_change_column_type_concurrently TABLE, COLUMN
  end
end
