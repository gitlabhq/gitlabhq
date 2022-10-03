# frozen_string_literal: true

class CreatePackagesRpmRepositoryFile < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    create_table :packages_rpm_repository_files do |t|
      t.timestamps_with_timezone

      t.references :project, index: true, null: false, foreign_key: { on_delete: :cascade }, type: :bigint
      t.integer :file_store, default: 1
      t.integer :status, default: 0, null: false, limit: 2
      t.integer :size
      t.binary :file_md5
      t.binary :file_sha1
      t.binary :file_sha256
      t.text :file, null: false, limit: 255
      t.text :file_name, null: false, limit: 255
    end
  end

  def down
    drop_table :packages_rpm_repository_files
  end
end
