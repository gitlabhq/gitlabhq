# frozen_string_literal: true

class CreatePartitionsForPCiBuildTags < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  enable_lock_retries!

  def up
    connection.execute(<<~SQL)
      LOCK TABLE p_ci_builds IN SHARE ROW EXCLUSIVE MODE;
      LOCK TABLE ONLY p_ci_build_tags IN ACCESS EXCLUSIVE MODE;

      CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_build_tags_100
        PARTITION OF p_ci_build_tags
        FOR VALUES IN (100);

      CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_build_tags_101
        PARTITION OF p_ci_build_tags
        FOR VALUES IN (101);

      CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_build_tags_102
        PARTITION OF p_ci_build_tags
        FOR VALUES IN (102);
    SQL
  end

  def down
    connection.execute(<<~SQL)
      DROP TABLE IF EXISTS gitlab_partitions_dynamic.ci_build_tags_100;
      DROP TABLE IF EXISTS gitlab_partitions_dynamic.ci_build_tags_101;
      DROP TABLE IF EXISTS gitlab_partitions_dynamic.ci_build_tags_102;
    SQL
  end
end
