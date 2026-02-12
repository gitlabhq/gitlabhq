# frozen_string_literal: true

class AddDigestToCacheRemoteEntries < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  disable_ddl_transaction!

  def up
    add_column :virtual_registries_container_cache_remote_entries, :digest, :text, if_not_exists: true

    add_text_limit :virtual_registries_container_cache_remote_entries, :digest, 71

    # Format: sha256:[64 hex chars] = 71 characters
    add_check_constraint :virtual_registries_container_cache_remote_entries,
      "(digest IS NULL OR char_length(digest) = 71)",
      'check_digest_length'
  end

  def down
    remove_check_constraint :virtual_registries_container_cache_remote_entries, 'check_digest_length'

    remove_column :virtual_registries_container_cache_remote_entries, :digest
  end
end
