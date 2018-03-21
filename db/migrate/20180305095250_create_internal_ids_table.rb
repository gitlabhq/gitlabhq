class CreateInternalIdsTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :internal_ids, id: :bigserial do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.integer :usage, null: false
      t.integer :last_value, null: false

      t.index [:usage, :project_id], unique: true
    end
  end
end
