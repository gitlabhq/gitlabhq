# frozen_string_literal: true

class CreatePartitionsForPCiBuildNames < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  enable_lock_retries!

  def up
    connection.execute(<<~SQL)
      LOCK TABLE p_ci_builds IN SHARE ROW EXCLUSIVE MODE;
      LOCK TABLE ONLY p_ci_build_names IN ACCESS EXCLUSIVE MODE;

      CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_build_names_100
        PARTITION OF p_ci_build_names
        FOR VALUES IN (100);

      CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_build_names_101
        PARTITION OF p_ci_build_names
        FOR VALUES IN (101);
    SQL
  end

  def down
    connection.execute(<<~SQL)
      DROP TABLE IF EXISTS gitlab_partitions_dynamic.ci_build_names_100;
      DROP TABLE IF EXISTS gitlab_partitions_dynamic.ci_build_names_101;
    SQL
  end
end
