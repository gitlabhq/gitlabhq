class CreateInternalIdsTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :internal_ids, id: :bigserial do |t|
      t.references :project
      t.integer :usage, null: false
      t.integer :last_value, null: false
    end

    unless index_exists?(:internal_ids, [:usage, :project_id])
      add_index :internal_ids, [:usage, :project_id], unique: true
    end

    unless foreign_key_exists?(:internal_ids, :project_id)
      add_concurrent_foreign_key :internal_ids, :projects, column: :project_id, on_delete: :cascade
    end
  end

  def down
    drop_table :internal_ids
  end

  private

  def foreign_key_exists?(table, column)
    foreign_keys(table).any? do |key|
      key.options[:column] == column.to_s
    end
  end
end
