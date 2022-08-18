# frozen_string_literal: true

class CreateUserProjectCallout < Gitlab::Database::Migration[2.0]
  def up
    create_table :user_project_callouts do |t|
      t.bigint :user_id, null: false
      t.bigint :project_id, null: false
      t.integer :feature_name, limit: 2, null: false
      t.datetime_with_timezone :dismissed_at

      t.index :project_id
      t.index [:user_id, :feature_name, :project_id], unique: true, name: 'index_project_user_callouts_feature'
    end
  end

  def down
    drop_table :user_project_callouts
  end
end
