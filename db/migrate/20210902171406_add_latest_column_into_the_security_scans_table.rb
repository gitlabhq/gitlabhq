# frozen_string_literal: true

class AddLatestColumnIntoTheSecurityScansTable < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    add_column :security_scans, :latest, :boolean, default: true, null: false
  end

  def down
    remove_column :security_scans, :latest
  end
end
