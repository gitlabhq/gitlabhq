class CreateUserCustomAttributes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :user_custom_attributes do |t|
      t.timestamps_with_timezone null: false
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :key, null: false
      t.string :value, null: false

      t.index [:user_id, :key], unique: true
      t.index [:key, :value]
    end
  end
end
