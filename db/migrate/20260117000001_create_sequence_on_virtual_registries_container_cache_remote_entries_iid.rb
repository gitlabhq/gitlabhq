# frozen_string_literal: true

class CreateSequenceOnVirtualRegistriesContainerCacheRemoteEntriesIid < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  TABLE_NAME = :virtual_registries_container_cache_remote_entries
  SEQUENCE_NAME = :virtual_registries_container_cache_remote_entries_iid_seq

  def up
    add_sequence(TABLE_NAME, :iid, SEQUENCE_NAME, 1)
  end

  def down
    drop_sequence(TABLE_NAME, :iid, SEQUENCE_NAME)
  end
end
