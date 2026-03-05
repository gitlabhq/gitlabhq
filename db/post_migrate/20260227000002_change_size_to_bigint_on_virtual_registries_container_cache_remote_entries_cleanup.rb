# frozen_string_literal: true

class ChangeSizeToBigintOnVirtualRegistriesContainerCacheRemoteEntriesCleanup < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!

  TABLE = :virtual_registries_container_cache_remote_entries
  COLUMN = :size

  def up
    cleanup_concurrent_column_type_change TABLE, COLUMN
  end

  def down
    undo_cleanup_concurrent_column_type_change TABLE, COLUMN, :integer, batch_column_name: :iid
  end
end
