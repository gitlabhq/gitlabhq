# frozen_string_literal: true

class FinalizeBackfillPackagesDebianGroupDistributionKeysGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPackagesDebianGroupDistributionKeysGroupId',
      table_name: :packages_debian_group_distribution_keys,
      column_name: :id,
      job_arguments: [:group_id, :packages_debian_group_distributions, :group_id, :distribution_id],
      finalize: true
    )
  end

  def down; end
end
