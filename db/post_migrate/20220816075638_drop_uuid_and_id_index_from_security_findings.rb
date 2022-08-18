# frozen_string_literal: true

class DropUuidAndIdIndexFromSecurityFindings < Gitlab::Database::Migration[2.0]
  INDEX_NAME = :index_on_security_findings_uuid_and_id_order_desc

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :security_findings, name: INDEX_NAME
  end

  def down
    add_concurrent_index :security_findings, [:uuid, :id], order: { id: :desc }, name: INDEX_NAME
  end
end
