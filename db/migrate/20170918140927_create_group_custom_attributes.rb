class CreateGroupCustomAttributes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :group_custom_attributes do |t|
      t.timestamps_with_timezone null: false
      t.references :group, null: false
      t.string :key, null: false
      t.string :value, null: false

      t.index [:group_id, :key], unique: true
      t.index [:key, :value]
    end

    add_foreign_key :group_custom_attributes, :namespaces, column: :group_id, on_delete: :cascade # rubocop: disable Migration/AddConcurrentForeignKey
  end
end
