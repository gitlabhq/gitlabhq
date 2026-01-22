# frozen_string_literal: true

class BackfillCiPartitionCurrentTimestamps < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    execute(<<~SQL)
      UPDATE ci_partitions
        SET
          current_from = COALESCE(
            (
              SELECT created_at FROM p_ci_builds WHERE partition_id = ci_partitions.id ORDER BY id LIMIT 1
            ),
            created_at
          )
        WHERE current_from IS NULL AND status IN (2, 3);
    SQL

    execute(<<~SQL)
      UPDATE ci_partitions
        SET
          current_until = (
            SELECT current_from FROM ci_partitions AS next_partition WHERE next_partition.id > ci_partitions.id ORDER BY next_partition.id LIMIT 1
          )
        WHERE current_until IS NULL AND status = 3;
    SQL
  end

  def down
    # No down migration needed as we're just populating data
  end
end
