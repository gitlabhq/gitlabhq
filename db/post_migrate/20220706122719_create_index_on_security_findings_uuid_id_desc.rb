# frozen_string_literal: true

class CreateIndexOnSecurityFindingsUuidIdDesc < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_on_security_findings_uuid_and_id_order_desc'

  def up
    add_concurrent_index(
      :security_findings,
      %i[uuid id],
      order: { id: :desc },
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(
      :security_findings,
      INDEX_NAME
    )
  end
end
