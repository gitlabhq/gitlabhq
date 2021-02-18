# frozen_string_literal: true

class CreateCustomEmojis < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:custom_emoji)
      create_table :custom_emoji do |t|
        t.references :namespace, index: false, null: false, foreign_key: { on_delete: :cascade }
        t.datetime_with_timezone :created_at, null: false
        t.datetime_with_timezone :updated_at, null: false
        t.text :name, null: false
        t.text :file, null: false
      end
    end

    unless index_exists?(:custom_emoji, [:namespace_id, :name], unique: true)
      add_index :custom_emoji, [:namespace_id, :name], unique: true
    end

    add_text_limit(:custom_emoji, :name, 36)
    add_text_limit(:custom_emoji, :file, 255)
  end

  def down
    drop_table :custom_emoji
  end
end
