# frozen_string_literal: true

class CreateSecretDetectionTokenStatus < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    create_table :secret_detection_token_statuses, id: false do |t|
      t.bigint :vulnerability_occurrence_id, primary_key: true, default: nil
      t.bigint :project_id, null: false
      t.timestamps_with_timezone null: false
      t.integer :status, limit: 2, null: false, default: 0

      t.index :project_id, name: 'idx_secret_detect_token_on_project_id'
    end
  end
end
