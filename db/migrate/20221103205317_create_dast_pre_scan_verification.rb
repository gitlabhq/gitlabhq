# frozen_string_literal: true

class CreateDastPreScanVerification < Gitlab::Database::Migration[2.0]
  def up
    create_table :dast_pre_scan_verifications do |t|
      t.references :dast_profile, null: false, foreign_key: { on_delete: :cascade },
                                  index: { name: 'index_dast_pre_scan_verifications_on_dast_profile_id' }

      t.bigint :ci_pipeline_id, null: false

      t.timestamps_with_timezone

      t.integer :status, default: 0, limit: 2, null: false

      t.index :ci_pipeline_id, unique: true, name: :index_dast_pre_scan_verifications_on_ci_pipeline_id
    end
  end

  def down
    drop_table :dast_pre_scan_verifications
  end
end
