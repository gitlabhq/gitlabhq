# frozen_string_literal: true

class CreateMergeRequestPredictions < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    create_table :merge_request_predictions, id: false do |t|
      t.references :merge_request,
        primary_key: true, null: false, type: :bigint,
        index: false, foreign_key: { on_delete: :cascade }

      t.timestamps_with_timezone null: false
      t.jsonb :suggested_reviewers, null: false, default: {}
    end
  end

  def down
    drop_table :merge_request_predictions
  end
end
