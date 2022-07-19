# frozen_string_literal: true

class CreateUserNamespaceCallouts < Gitlab::Database::Migration[2.0]
  def up
    create_table :user_namespace_callouts do |t|
      t.bigint :user_id, null: false
      t.bigint :namespace_id, null: false, index: true
      t.datetime_with_timezone :dismissed_at
      t.integer :feature_name, limit: 2, null: false
    end
  end

  def down
    drop_table :user_namespace_callouts
  end
end
