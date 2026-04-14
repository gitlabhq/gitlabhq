# frozen_string_literal: true

class CreatePartitionedMergeRequestDiffCommitsV2 < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.11'

  disable_ddl_transaction!

  SOURCE_TABLE_NAME = 'merge_request_diff_commits'
  PARTITION_SIZE = 2_000_000
  INDEX_NAME = 'index_partitioned_mrdc_on_merge_request_commits_metadata_id'

  def up
    return if table_exists?(partitioned_table_name)

    create_table partitioned_table_name,
      options: 'PARTITION BY RANGE(project_id)',
      primary_key: [:merge_request_diff_id, :relative_order, :project_id] do |t|
      t.bigint :merge_request_commits_metadata_id, null: false
      t.bigint :merge_request_diff_id, null: false
      t.references :project, null: false
      t.integer :relative_order, null: false
      t.index :merge_request_commits_metadata_id, name: INDEX_NAME
    end

    create_partitions
  end

  def down
    drop_partitioned_table_for(SOURCE_TABLE_NAME)
  end

  private

  def create_partitions
    min_id = connection
               .select_value("select min_value from pg_sequences where sequencename = 'projects_id_seq'") || 1

    max_id = Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
      Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed do
        define_batchable_model('projects', connection: connection).maximum(:id) || min_id
      end
    end

    create_int_range_partitions(partitioned_table_name, PARTITION_SIZE, min_id, max_id)
  end

  def partitioned_table_name
    @_partitioned_table_name ||= tmp_table_name(SOURCE_TABLE_NAME)
  end
end
