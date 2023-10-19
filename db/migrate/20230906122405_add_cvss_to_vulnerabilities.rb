# frozen_string_literal: true

class AddCvssToVulnerabilities < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :vulnerabilities, :cvss, :jsonb, default: [], if_not_exists: true
    end
  end

  def down
    with_lock_retries do
      remove_column :vulnerabilities, :cvss, if_exists: true
    end
  end
end
