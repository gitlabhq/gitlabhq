# frozen_string_literal: true

class CreateSeqOnVirtualRegistriesPackagesNpmCacheLocalEntriesIid < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  TABLE_NAME = :virtual_registries_packages_npm_cache_local_entries
  SEQ_NAME = :virtual_registries_packages_npm_cache_local_entries_iid_seq

  def up
    add_sequence(TABLE_NAME, :iid, SEQ_NAME, 1)
  end

  def down
    drop_sequence(TABLE_NAME, :iid, SEQ_NAME)
  end
end
