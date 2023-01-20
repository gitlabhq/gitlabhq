# frozen_string_literal: true

class CreateNamespacesStorageLimitExclusions < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    create_table :namespaces_storage_limit_exclusions do |t|
      t.references :namespace,
                   foreign_key: { on_delete: :cascade },
                   index: true,
                   null: false
      t.text :reason, null: false, limit: 255
      t.timestamps_with_timezone null: false
    end
  end

  def down
    drop_table :namespaces_storage_limit_exclusions
  end
end
