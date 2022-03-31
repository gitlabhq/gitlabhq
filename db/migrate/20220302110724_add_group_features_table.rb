# frozen_string_literal: true

class AddGroupFeaturesTable < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    create_table :group_features, id: false do |t|
      t.references :group, index: false, foreign_key: { to_table: :namespaces, on_delete: :cascade }, null: false
      t.timestamps_with_timezone null: false
      t.integer :wiki_access_level, default: Featurable::ENABLED, null: false, limit: 2
    end

    execute('ALTER TABLE group_features ADD PRIMARY KEY (group_id)')
  end

  def down
    drop_table :group_features
  end
end
