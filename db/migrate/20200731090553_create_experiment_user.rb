# frozen_string_literal: true

class CreateExperimentUser < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    create_table :experiment_users do |t|
      t.bigint :experiment_id, null: false
      t.bigint :user_id, null: false
      t.integer :group_type, limit: 2, null: false, default: 0
      t.timestamps_with_timezone null: false
    end

    add_index :experiment_users, :experiment_id
    add_index :experiment_users, :user_id
  end

  def down
    drop_table :experiment_users
  end
end
