# frozen_string_literal: true

class DropExperimentUsersTable < Gitlab::Database::Migration[2.0]
  def up
    drop_table :experiment_users
  end

  def down
    create_table :experiment_users do |t| # rubocop:disable Migration/SchemaAdditionMethodsNoPost
      t.bigint :experiment_id, null: false
      t.bigint :user_id, null: false
      t.integer :group_type, limit: 2, null: false, default: 0
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :converted_at
      t.jsonb :context, null: false, default: {}
    end

    add_index :experiment_users, :experiment_id
    add_index :experiment_users, :user_id
  end
end
