# frozen_string_literal: true

class CreateDastPreScanVerificationStep < Gitlab::Database::Migration[2.1]
  def up
    create_table :dast_pre_scan_verification_steps do |t|
      t.references :dast_pre_scan_verification,
                   null: false, foreign_key: { on_delete: :cascade },
                   index: { name: 'i_dast_pre_scan_verification_steps_on_pre_scan_verification_id' }
      t.timestamps_with_timezone
      t.text :name, limit: 255
      t.text :verification_errors, array: true, default: [], null: false
    end
  end

  def down
    drop_table :dast_pre_scan_verification_steps
  end
end
