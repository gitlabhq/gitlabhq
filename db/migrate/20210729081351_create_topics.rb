# frozen_string_literal: true

class CreateTopics < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    create_table_with_constraints :topics do |t|
      t.text :name, null: false
      t.text_limit :name, 255

      t.index :name, unique: true

      t.timestamps_with_timezone
    end
  end

  def down
    with_lock_retries do
      drop_table :topics
    end
  end
end
