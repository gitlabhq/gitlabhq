# frozen_string_literal: true

class AddProjectFkToSupplyChainSigningCertificates < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  TABLE_NAME = :supply_chain_signing_certificates

  def up
    add_concurrent_foreign_key TABLE_NAME, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, :projects, column: :project_id
    end
  end
end
