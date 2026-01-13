# frozen_string_literal: true

class CreateSequenceOnVirtualRegistriesPackagesMavenCacheRemoteEntriesIid < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  TABLE_NAME = :virtual_registries_packages_maven_cache_remote_entries
  SEQUENCE_NAME = :virtual_registries_packages_maven_cache_remote_entries_iid_seq

  def up
    add_sequence(TABLE_NAME, :iid, SEQUENCE_NAME, 1)
  end

  def down
    drop_sequence(TABLE_NAME, :iid, SEQUENCE_NAME)
  end
end
