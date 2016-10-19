class CreateLabelPriorities < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'This migration adds foreign keys'

  disable_ddl_transaction!

  def up
    create_table :label_priorities do |t|
      t.references :project, foreign_key: { on_delete: :cascade }, null: false
      t.references :label, foreign_key: { on_delete: :cascade }, null: false
      t.integer :priority, null: false

      t.timestamps null: false
    end

    add_concurrent_index :label_priorities, [:project_id, :label_id], unique: true
    add_concurrent_index :label_priorities, :priority
  end

  def down
    drop_table :label_priorities
  end
end
