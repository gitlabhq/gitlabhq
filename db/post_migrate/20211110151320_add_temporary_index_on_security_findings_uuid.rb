# frozen_string_literal: true

class AddTemporaryIndexOnSecurityFindingsUuid < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = "tmp_index_uuid_is_null"

  def up
    add_concurrent_index(
      :security_findings,
      :id,
      where: "uuid IS NULL",
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
