# frozen_string_literal: true

class AddSynchronousFkValidationFromPCiBuildsPartitionsToCiStages < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '16.9'

  disable_ddl_transaction!

  COLUMNS = [:partition_id, :stage_id]
  SOURCE_TABLE_NAME = :p_ci_builds
  TARGET_TABLE_NAME = :ci_stages
  COLUMN = :stage_id
  TARGET_COLUMN = :id
  FK_NAME = :fk_3a9eaa254d_p
  PARTITION_COLUMN = :partition_id

  def up
    old_constraint = Gitlab::Database::PostgresForeignKey
                       .by_constrained_table_name(SOURCE_TABLE_NAME)
                       .by_referenced_table_name(TARGET_TABLE_NAME)
                       .first

    unless old_constraint&.valid?
      raise "Expected to find a valid foreign key between #{SOURCE_TABLE_NAME} and #{TARGET_TABLE_NAME}"
    end

    validate_partitioned_foreign_key(SOURCE_TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    # no-op
  end
end
