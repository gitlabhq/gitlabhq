# frozen_string_literal: true

class DropPackagesComposerCacheFilesTable < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  TABLE = :packages_composer_cache_files

  def up
    drop_table TABLE
  end

  def down
    create_table TABLE do |t|
      t.timestamps_with_timezone null: false

      t.datetime_with_timezone :delete_at
      t.bigint :namespace_id
      t.integer :file_store, null: false, default: 1, limit: 2
      t.text :file, null: false, limit: 255
      t.binary :file_sha256, null: false

      t.index [:delete_at, :id], name: :composer_cache_files_index_on_deleted_at
      t.index [:id], name: :index_composer_cache_files_where_namespace_id_is_null, where: 'namespace_id IS NULL'
      t.index [:namespace_id, :file_sha256], name: :index_packages_composer_cache_namespace_and_sha, unique: true
    end
  end
end
