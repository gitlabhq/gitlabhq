# frozen_string_literal: true

class AddStatusColumnToSecurityScansTable < Gitlab::Database::Migration[1.0]
  def change
    add_column :security_scans, :status, :integer, limit: 1, default: 0, null: false
  end
end
