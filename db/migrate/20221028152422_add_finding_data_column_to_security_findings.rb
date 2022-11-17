# frozen_string_literal: true

class AddFindingDataColumnToSecurityFindings < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    add_column :security_findings, :finding_data, :jsonb, default: {}, null: false
  end

  def down
    remove_column :security_findings, :finding_data
  end
end
