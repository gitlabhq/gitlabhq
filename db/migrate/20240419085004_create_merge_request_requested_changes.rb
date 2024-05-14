# frozen_string_literal: true

class CreateMergeRequestRequestedChanges < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    create_table :merge_request_requested_changes do |t|
      t.bigint :project_id, null: false
      t.bigint :user_id, null: false
      t.bigint :merge_request_id, null: false

      t.timestamps_with_timezone null: false

      t.index :project_id
      t.index :user_id
      t.index :merge_request_id
    end
  end
end
