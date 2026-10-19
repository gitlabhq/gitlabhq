# frozen_string_literal: true

class ReinstateDuoCodeReviewFindings < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  TABLE_NAME = :duo_code_review_findings

  # Replaces 20261014031412, disabled after it could not lock `notes` on GitLab.com.
  # Foreign keys are added concurrently in the following migrations.
  # `if_not_exists` covers environments where the original migration already ran.
  def up
    create_table TABLE_NAME, id: false, if_not_exists: true do |t|
      # A plain bigint key: the id comes from the note, so no sequence is needed.
      t.bigint :note_id, primary_key: true, default: nil
      t.bigint :project_id, null: false
      t.bigint :merge_request_id, null: false
      t.bigint :workflow_id
      t.datetime_with_timezone :created_at, null: false
      t.integer :severity, limit: 2, null: false
      t.integer :depth, limit: 2, null: false
      t.integer :confidence, limit: 2
      t.text :category, null: false, limit: 255

      t.check_constraint 'confidence BETWEEN 0 AND 10', name: 'chk_duo_code_review_findings_confidence'

      t.index :project_id
      t.index :merge_request_id
      t.index :workflow_id
    end
  end

  def down
    drop_table TABLE_NAME, if_exists: true
  end
end
