# frozen_string_literal: true

class CreateNamespaceDescendantsTable < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '16.8'

  def up
    execute <<~SQL
      CREATE TABLE namespace_descendants (
        namespace_id bigint NOT NULL,
        self_and_descendant_group_ids bigint[] NOT NULL DEFAULT ARRAY[]::bigint[],
        all_project_ids bigint[] NOT NULL DEFAULT ARRAY[]::bigint[],
        traversal_ids bigint[] NOT NULL DEFAULT ARRAY[]::bigint[],
        outdated_at timestamp with time zone,
        calculated_at timestamp with time zone,
        PRIMARY KEY(namespace_id)
      )
      PARTITION BY HASH (namespace_id);
    SQL

    execute <<~SQL
      CREATE INDEX
      index_on_namespace_descendants_outdated
      ON namespace_descendants (namespace_id)
      WHERE outdated_at IS NOT NULL
    SQL

    create_hash_partitions(:namespace_descendants, 32)
  end

  def down
    drop_table :namespace_descendants
  end
end
