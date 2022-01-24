# frozen_string_literal: true

class DropPositionFromSecurityFindings < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    remove_column :security_findings, :position, :integer
  end
end
