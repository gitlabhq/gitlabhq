# frozen_string_literal: true

class AddForeignKeyToBuildsMetadata < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_foreign_key :p_ci_builds_metadata,
                                           :ci_runner_machines,
                                           column: :runner_machine_id,
                                           on_delete: :nullify
  end

  def down
    remove_foreign_key_if_exists :p_ci_builds_metadata, column: :runner_machine_id
  end
end
