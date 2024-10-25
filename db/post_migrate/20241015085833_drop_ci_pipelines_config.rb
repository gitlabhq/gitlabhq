# frozen_string_literal: true

class DropCiPipelinesConfig < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def up
    drop_table(:ci_pipelines_config, if_exists: true)

    execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS #{fully_qualified_partition_name(100)}
        PARTITION OF p_ci_pipelines_config FOR VALUES IN (100);

      CREATE TABLE IF NOT EXISTS #{fully_qualified_partition_name(101)}
        PARTITION OF p_ci_pipelines_config FOR VALUES IN (101);

      CREATE TABLE IF NOT EXISTS #{fully_qualified_partition_name(102)}
        PARTITION OF p_ci_pipelines_config FOR VALUES IN (102);
    SQL
  end

  def down
    drop_table(fully_qualified_partition_name(100), if_exists: true)
    drop_table(fully_qualified_partition_name(101), if_exists: true)
    drop_table(fully_qualified_partition_name(102), if_exists: true)

    execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS ci_pipelines_config
        PARTITION OF p_ci_pipelines_config FOR VALUES IN (100, 101, 102);
    SQL
  end

  private

  def fully_qualified_partition_name(value)
    "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.ci_pipelines_config_#{value}"
  end
end
