# frozen_string_literal: true

class CreateCiSecureFiles < Gitlab::Database::Migration[1.0]
  def up
    create_table :ci_secure_files do |t|
      t.bigint :project_id, index: true, null: false
      t.timestamps_with_timezone null: false
      t.integer :file_store, limit: 2, null: false, default: 1
      t.integer :permissions, null: false, default: 0, limit: 2
      t.text :name, null: false, limit: 255
      t.text :file, null: false, limit: 255
      t.binary :checksum, null: false
    end
  end

  def down
    drop_table :ci_secure_files, if_exists: true
  end
end
