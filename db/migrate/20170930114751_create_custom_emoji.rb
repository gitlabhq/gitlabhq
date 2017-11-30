class CreateCustomEmoji < ActiveRecord::Migration
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :custom_emoji do |t|
      t.references :namespace, index: true, null: false, foreign_key: { on_delete: :cascade }
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
      t.string :name, null: false, limit: 36
      t.string :file, null: false
    end

    if Gitlab::Database.postgresql?
      execute 'CREATE INDEX CONCURRENTLY index_on_custom_emoji_lower_name ON custom_emoji (LOWER(name), namespace_id);'
    end
  end

  def down
    drop_table :custom_emoji
  end
end
