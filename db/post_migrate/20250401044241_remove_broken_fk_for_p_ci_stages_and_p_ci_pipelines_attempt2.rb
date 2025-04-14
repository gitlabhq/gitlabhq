# frozen_string_literal: true

class RemoveBrokenFkForPCiStagesAndPCiPipelinesAttempt2 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  milestone '17.11'
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :p_ci_stages
  TARGET_TABLE_NAME = :p_ci_pipelines
  FK_NAME = :fk_fb57e6cc56_p

  def up
    return unless can_execute_on?(:ci_pipelines, :ci_stages)

    with_lock_retries do
      remove_foreign_key_if_exists(
        SOURCE_TABLE_NAME,
        TARGET_TABLE_NAME,
        name: FK_NAME,
        reverse_lock_order: true
      )
    end
  end

  def down
    # no-op
    # Since we recreate the fk in db/post_migrate/20250326204934_remove_broken_fk_for_p_ci_stages_and_p_ci_pipelines.rb
  end
end
