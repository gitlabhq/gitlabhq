# frozen_string_literal: true

class CreateUserGroupCallout < ActiveRecord::Migration[6.1]
  def up
    create_table :user_group_callouts do |t|
      t.bigint :user_id, null: false
      t.bigint :group_id, null: false
      t.integer :feature_name, limit: 2, null: false
      t.datetime_with_timezone :dismissed_at

      t.index :group_id
      t.index [:user_id, :feature_name, :group_id], unique: true, name: 'index_group_user_callouts_feature'
    end
  end

  def down
    drop_table :user_group_callouts
  end
end
