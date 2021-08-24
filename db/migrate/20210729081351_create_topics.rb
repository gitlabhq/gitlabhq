# frozen_string_literal: true

class CreateTopics < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def change
    create_table_with_constraints :topics do |t|
      t.text :name, null: false
      t.text_limit :name, 255

      t.index :name, unique: true

      t.timestamps_with_timezone
    end
  end
end
