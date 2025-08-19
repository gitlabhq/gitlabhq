# frozen_string_literal: true

class AddGeneratedRefCommit < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.3'
  disable_ddl_transaction!

  INDEX_NAME_MERGE_REQUEST = 'p_index_generated_ref_commits_on_merge_request_id'
  INDEX_NAME_COMMITS_AND_PROJECT_ID = 'p_index_generated_ref_commits_on_project_id_and_commit_sha'
  TABLE_NAME = :p_generated_ref_commits
  PARTITION_SIZE = 2_000_000

  def up
    create_table TABLE_NAME,
      options: 'PARTITION BY RANGE (project_id)',
      primary_key: [:id, :project_id], if_not_exists: true do |t|
      t.bigserial :id, null: false
      t.bigint :merge_request_iid, null: false
      t.bigint :project_id, null: false
      t.timestamps_with_timezone
      t.binary :commit_sha, null: false
    end

    add_concurrent_partitioned_index TABLE_NAME, [:project_id, :merge_request_iid], name: INDEX_NAME_MERGE_REQUEST

    add_concurrent_partitioned_index TABLE_NAME, [:project_id, :commit_sha],
      name: INDEX_NAME_COMMITS_AND_PROJECT_ID,
      using: :btree

    create_partitions
  end

  def down
    drop_table TABLE_NAME
  end

  private

  def create_partitions
    min_id = 1
    max_id = Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
      Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed do
        define_batchable_model('projects', connection: connection).maximum(:id) || min_id
      end
    end

    create_int_range_partitions(TABLE_NAME, PARTITION_SIZE, min_id, max_id)
  end
end
