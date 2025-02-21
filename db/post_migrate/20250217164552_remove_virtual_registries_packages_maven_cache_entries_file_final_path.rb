# frozen_string_literal: true

class RemoveVirtualRegistriesPackagesMavenCacheEntriesFileFinalPath < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  TABLE_NAME = :virtual_registries_packages_maven_cache_entries
  COLUMN = :file_final_path

  def up
    remove_column TABLE_NAME, COLUMN
  end

  def down
    add_column TABLE_NAME, COLUMN, :text, if_not_exists: true

    add_text_limit TABLE_NAME, COLUMN, 1024
  end
end
