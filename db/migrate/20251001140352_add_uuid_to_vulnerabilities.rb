# frozen_string_literal: true

class AddUuidToVulnerabilities < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :vulnerabilities, :uuid, :uuid, if_not_exists: true
    end
  end

  def down
    with_lock_retries do
      remove_column :vulnerabilities, :uuid, if_exists: true
    end
  end
end
