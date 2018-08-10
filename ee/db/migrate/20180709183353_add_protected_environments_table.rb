# frozen_string_literal: true
class AddProtectedEnvironmentsTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :protected_environments do |t|
      t.references :project, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.string :name, null: false
    end

    add_index :protected_environments, [:project_id, :name], unique: true
  end
end
