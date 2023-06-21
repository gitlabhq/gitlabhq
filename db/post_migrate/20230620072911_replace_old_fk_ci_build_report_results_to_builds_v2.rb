# frozen_string_literal: true

class ReplaceOldFkCiBuildReportResultsToBuildsV2 < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    return if new_foreign_key_exists?

    with_lock_retries do
      remove_foreign_key_if_exists :ci_build_report_results, :ci_builds,
        name: :fk_rails_16cb1ff064_p, reverse_lock_order: true

      rename_constraint :ci_build_report_results, :temp_fk_rails_16cb1ff064_p, :fk_rails_16cb1ff064_p
    end
  end

  def down
    return unless new_foreign_key_exists?

    add_concurrent_foreign_key :ci_build_report_results, :ci_builds,
      name: :temp_fk_rails_16cb1ff064_p,
      column: [:partition_id, :build_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      validate: true,
      reverse_lock_order: true

    switch_constraint_names :ci_build_report_results, :fk_rails_16cb1ff064_p, :temp_fk_rails_16cb1ff064_p
  end

  private

  def new_foreign_key_exists?
    foreign_key_exists?(:ci_build_report_results, :p_ci_builds, name: :fk_rails_16cb1ff064_p)
  end
end
