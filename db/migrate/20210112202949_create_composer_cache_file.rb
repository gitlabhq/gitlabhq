# frozen_string_literal: true

class CreateComposerCacheFile < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    # rubocop:disable Migration/AddLimitToTextColumns
    create_table_with_constraints :packages_composer_cache_files do |t|
      t.timestamps_with_timezone

      # record can be deleted after `delete_at`
      t.datetime_with_timezone :delete_at

      # which namespace it belongs to
      t.integer :namespace_id, null: true

      # file storage related fields
      t.integer :file_store, limit: 2, null: false, default: 1
      t.text :file, null: false
      t.binary :file_sha256, null: false

      t.index [:namespace_id, :file_sha256], name: "index_packages_composer_cache_namespace_and_sha", using: :btree, unique: true
      t.foreign_key :namespaces, column: :namespace_id, on_delete: :nullify

      t.text_limit :file, 255
    end
  end

  def down
    drop_table :packages_composer_cache_files
  end
end
