# frozen_string_literal: true

class FinalizeHkBackfillIssueCustomerRelationsContactsNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillIssueCustomerRelationsContactsNamespaceId',
      table_name: :issue_customer_relations_contacts,
      column_name: :id,
      job_arguments: [:namespace_id, :issues, :namespace_id, :issue_id],
      finalize: true
    )
  end

  def down; end
end
