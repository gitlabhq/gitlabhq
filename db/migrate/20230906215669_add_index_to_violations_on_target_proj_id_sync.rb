# frozen_string_literal: true

class AddIndexToViolationsOnTargetProjIdSync < Gitlab::Database::Migration[2.1]
  TABLE_NAME = 'merge_requests_compliance_violations'
  INDEX_NAME = 'i_compliance_violations_for_export'

  disable_ddl_transaction!

  def up
    add_concurrent_index TABLE_NAME, [:target_project_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
