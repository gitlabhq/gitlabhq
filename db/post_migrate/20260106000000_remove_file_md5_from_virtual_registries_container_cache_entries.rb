# frozen_string_literal: true

class RemoveFileMd5FromVirtualRegistriesContainerCacheEntries < Gitlab::Database::Migration[2.3]
  milestone '18.8'
  disable_ddl_transaction!

  TABLE_NAME = :virtual_registries_container_cache_entries

  def up
    remove_column TABLE_NAME, :file_md5, if_exists: true
  end

  def down
    add_column TABLE_NAME, :file_md5, :binary, if_not_exists: true

    add_check_constraint TABLE_NAME,
      '((file_md5 IS NULL) OR (octet_length(file_md5) = 16))',
      'chk_rails_a97edf3d51'
  end
end
