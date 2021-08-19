# frozen_string_literal: true

class CreatePostgresAsyncIndexesTable < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def change
    create_table_with_constraints :postgres_async_indexes do |t|
      t.timestamps_with_timezone null: false

      t.text :name, null: false
      t.text :definition, null: false
      t.text :table_name, null: false

      t.text_limit :name, 63
      t.text_limit :definition, 2048
      t.text_limit :table_name, 63

      t.index :name, unique: true
    end
  end
end
