# frozen_string_literal: true

class CreateNamespaceDeletionSchedules < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    create_table :namespace_deletion_schedules, id: false do |t|
      t.bigint :namespace_id, null: false, primary_key: true
      t.bigint :user_id, null: false
      t.datetime_with_timezone :marked_for_deletion_at, null: false

      t.index :user_id
      t.index :marked_for_deletion_at
    end
  end
end
