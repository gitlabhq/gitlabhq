class CreateLists < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :lists do |t|
      t.references :board, index: true, foreign_key: true, null: false
      t.references :label, index: true, foreign_key: true
      t.integer :list_type, null: false, default: 0
      t.integer :position, null: false

      t.timestamps null: false
    end
  end
end
