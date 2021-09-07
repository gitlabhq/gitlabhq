# frozen_string_literal: true

class AddLatestColumnIntoTheSecurityScansTable < Gitlab::Database::Migration[1.0]
  def up
    with_lock_retries do
      add_column :security_scans, :latest, :boolean, default: true, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :security_scans, :latest
    end
  end
end
