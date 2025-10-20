# frozen_string_literal: true

class DropNamespaceDeletionSchedules < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    drop_table :namespace_deletion_schedules, if_exists: true
  end

  def down
    create_table :namespace_deletion_schedules, id: false do |t|
      t.bigint :namespace_id, null: false, primary_key: true
      t.bigint :user_id, null: false
      t.datetime_with_timezone :marked_for_deletion_at, null: false

      t.index :user_id
      t.index :marked_for_deletion_at
    end
  end
end
