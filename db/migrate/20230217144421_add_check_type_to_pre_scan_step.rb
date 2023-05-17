# frozen_string_literal: true

class AddCheckTypeToPreScanStep < Gitlab::Database::Migration[2.1]
  def up
    add_column :dast_pre_scan_verification_steps, :check_type, :integer, limit: 2, default: 0, null: false
  end

  def down
    remove_column :dast_pre_scan_verification_steps, :check_type
  end
end
