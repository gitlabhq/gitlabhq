# frozen_string_literal: true

class AddIndexForOrganizationIdToAbuseReportAssignees < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  TABLE_NAME = :abuse_report_assignees
  INDEX_NAME = 'index_abuse_report_assignees_on_organization_id'

  def up
    add_concurrent_index TABLE_NAME, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
