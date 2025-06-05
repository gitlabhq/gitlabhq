# frozen_string_literal: true

class DropDuplicateIndexCiPipelineVariable < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  DUPLICATED_INDEXES = %w[index_ad9d0b5002 index_d45be46b0d]

  def up
    attached_index_name = identify_index_name
    return unless attached_index_name

    # One of the two indexes are attached to the partitioned table index. We are dropping the other one
    non_attached_index_name = (DUPLICATED_INDEXES - [attached_index_name]).first

    with_lock_retries do
      connection.execute(<<~SQL)
        DROP INDEX IF EXISTS gitlab_partitions_dynamic.#{non_attached_index_name};
      SQL
    end

    return if index_exists?('gitlab_partitions_dynamic.ci_pipeline_variables', 'project_id', name: 'index_d45be46b0d')

    with_lock_retries do
      connection.execute(<<~SQL)
        ALTER INDEX IF EXISTS gitlab_partitions_dynamic.#{attached_index_name} RENAME TO index_d45be46b0d;
      SQL
    end
  end

  def down
    # no-op
  end

  private

  def identify_index_name
    connection.select_value(<<~SQL)
      SELECT child_idx.relname
      FROM pg_inherits inh
      JOIN pg_class parent_idx ON inh.inhparent = parent_idx.oid
      JOIN pg_class child_idx ON inh.inhrelid = child_idx.oid
      JOIN pg_index parent_i ON parent_idx.oid = parent_i.indexrelid
      JOIN pg_index child_i ON child_idx.oid = child_i.indexrelid
      JOIN pg_class parent_tbl ON parent_i.indrelid = parent_tbl.oid
      JOIN pg_class child_tbl ON child_i.indrelid = child_tbl.oid
      WHERE parent_idx.relkind = 'I'  -- Only indexes
        AND parent_idx.relname = 'index_p_ci_pipeline_variables_on_project_id'
        AND parent_tbl.relname = 'p_ci_pipeline_variables'
        AND child_tbl.relname = 'ci_pipeline_variables';
    SQL
  end
end
