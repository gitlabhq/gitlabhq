# frozen_string_literal: true

class FinalizeHkBackfillPagesDomainAcmeOrdersProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPagesDomainAcmeOrdersProjectId',
      table_name: :pages_domain_acme_orders,
      column_name: :id,
      job_arguments: [:project_id, :pages_domains, :project_id, :pages_domain_id],
      finalize: true
    )
  end

  def down; end
end
