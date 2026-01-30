# frozen_string_literal: true

class CreateSeqOnVirtualRegistriesPackagesMavenCacheLocalEntries < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  TABLE_NAME = :virtual_registries_packages_maven_cache_local_entries
  SEQ_NAME = :virtual_registries_packages_maven_cache_local_entries_iid_seq

  def up
    add_sequence(TABLE_NAME, :iid, SEQ_NAME, 1)
  end

  def down
    drop_sequence(TABLE_NAME, :iid, SEQ_NAME)
  end
end
