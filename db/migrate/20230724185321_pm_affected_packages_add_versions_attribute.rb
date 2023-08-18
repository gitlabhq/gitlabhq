# frozen_string_literal: true

class PmAffectedPackagesAddVersionsAttribute < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :pm_affected_packages, :versions, :jsonb, default: [], null: false
  end
end
