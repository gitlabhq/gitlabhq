# frozen_string_literal: true

class AddFkFromCiRunnerTaggingsToPartitionedCiRunners < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.6'

  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :ci_runner_taggings
  TARGET_TABLE_NAME = :ci_runners_e59bb2812d
  COLUMN = %i[runner_id runner_type]
  TARGET_COLUMN = %i[id runner_type]
  FK_NAME = :fk_rails_84f15fe4c6
  PARTITION_PREFIXES = %w[instance_type group_type project_type]

  def up
    PARTITION_PREFIXES.each do |partition|
      add_concurrent_foreign_key(
        "#{SOURCE_TABLE_NAME}_#{partition}", "#{partition}_#{TARGET_TABLE_NAME}",
        name: FK_NAME,
        column: COLUMN,
        target_column: TARGET_COLUMN,
        validate: true,
        on_update: :cascade,
        on_delete: :cascade,
        reverse_lock_order: true
      )
    end
  end

  def down
    PARTITION_PREFIXES.each do |partition|
      with_lock_retries do
        remove_foreign_key_if_exists(
          "#{SOURCE_TABLE_NAME}_#{partition}", "#{partition}_#{TARGET_TABLE_NAME}",
          name: FK_NAME, reverse_lock_order: true
        )
      end
    end
  end
end
