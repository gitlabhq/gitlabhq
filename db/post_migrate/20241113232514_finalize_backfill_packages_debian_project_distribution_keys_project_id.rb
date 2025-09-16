# frozen_string_literal: true

class FinalizeBackfillPackagesDebianProjectDistributionKeysProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPackagesDebianProjectDistributionKeysProjectId',
      table_name: :packages_debian_project_distribution_keys,
      column_name: :id,
      job_arguments: [:project_id, :packages_debian_project_distributions, :project_id, :distribution_id],
      finalize: true
    )
  end

  def down; end
end
