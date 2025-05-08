# frozen_string_literal: true

class MovePipelineVariablesToDynamicSchema < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  DYNAMIC_SCHEMA = Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA
  TABLE_NAME = :ci_pipeline_variables

  def up
    connection.execute(<<~SQL)
      ALTER TABLE IF EXISTS #{TABLE_NAME} SET SCHEMA #{DYNAMIC_SCHEMA};
    SQL
  end

  def down
    connection.execute(<<~SQL)
      ALTER TABLE IF EXISTS #{DYNAMIC_SCHEMA}.#{TABLE_NAME} SET SCHEMA #{connection.current_schema};
    SQL
  end
end
