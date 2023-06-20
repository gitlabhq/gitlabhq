# frozen_string_literal: true

class CreateCiJobAnnotationsPartitions < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_job_annotations_100
        PARTITION OF p_ci_job_annotations
        FOR VALUES IN (100);
    SQL
  end

  def down
    connection.execute(<<~SQL)
      DROP TABLE IF EXISTS gitlab_partitions_dynamic.ci_job_annotations_100;
    SQL
  end
end
