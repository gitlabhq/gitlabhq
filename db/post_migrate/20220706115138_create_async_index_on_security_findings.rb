# frozen_string_literal: true

class CreateAsyncIndexOnSecurityFindings < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_on_security_findings_uuid_and_id_order_desc'

  def up
    prepare_async_index(
      :security_findings,
      %i[uuid id],
      order: { id: :desc },
      name: INDEX_NAME
    )
  end

  def down
    unprepare_async_index(
      :security_findings,
      %i[uuid id],
      name: INDEX_NAME
    )
  end
end
