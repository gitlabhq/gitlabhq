# frozen_string_literal: true

class AddPipelinesIdRangeToCiPartitions < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  CONSTRAINT_NAME = 'check_ci_partitions_pipelines_id_range_no_overlap'

  def up
    add_column :ci_partitions, :pipelines_id_range, :int8range

    execute(<<~SQL)
      ALTER TABLE ci_partitions
        ADD CONSTRAINT #{CONSTRAINT_NAME}
        EXCLUDE USING gist (pipelines_id_range WITH &&)
        WHERE (pipelines_id_range IS NOT NULL)
    SQL
  end

  def down
    execute("ALTER TABLE ci_partitions DROP CONSTRAINT IF EXISTS #{CONSTRAINT_NAME}")

    remove_column :ci_partitions, :pipelines_id_range
  end
end
