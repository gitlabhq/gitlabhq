# frozen_string_literal: true

class AddPartitionNumberToSecurityFindings < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :security_findings, :partition_number, :integer, default: 1, null: false
  end
end
