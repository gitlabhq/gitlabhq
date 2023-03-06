# frozen_string_literal: true

class ValidatePartitioningFkOnPCiBuildsMetadataPartitions < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :p_ci_builds_metadata
  FK_NAME = :fk_e20479742e_p

  def up
    Gitlab::Database::PostgresPartitionedTable.each_partition(SOURCE_TABLE_NAME) do |partition|
      next unless foreign_key_exists?(partition.identifier, name: FK_NAME)

      validate_foreign_key(partition.identifier, nil, name: FK_NAME)
    end
  end

  def down
    # No-op
  end
end
