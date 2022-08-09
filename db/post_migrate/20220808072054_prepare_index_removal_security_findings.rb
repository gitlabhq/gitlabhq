# frozen_string_literal: true

class PrepareIndexRemovalSecurityFindings < Gitlab::Database::Migration[2.0]
  INDEX_NAME = :index_on_security_findings_uuid_and_id_order_desc

  def up
    prepare_async_index_removal :security_findings, [:uuid, :id], name: INDEX_NAME
  end

  def down
    unprepare_async_index_by_name :security_findings, INDEX_NAME
  end
end
