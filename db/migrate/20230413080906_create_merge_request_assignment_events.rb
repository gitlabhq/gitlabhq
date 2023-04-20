# frozen_string_literal: true

class CreateMergeRequestAssignmentEvents < Gitlab::Database::Migration[2.1]
  def change
    create_table :merge_request_assignment_events do |t|
      t.references :user, null: true, index: true, foreign_key: { on_delete: :nullify }
      t.bigint :merge_request_id, null: false
      t.datetime_with_timezone :created_at, null: false, default: -> { 'NOW()' }
      t.integer :action, limit: 2, null: false, default: 1

      t.index %i[merge_request_id action created_at id],
        name: 'index_on_mr_assignment_events_mr_id_action_created_at_id'
    end
  end
end
