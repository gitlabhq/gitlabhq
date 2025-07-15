# frozen_string_literal: true

class CreateAiActiveContextCodeRepositories < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.2'

  TABLE_NAME = :p_ai_active_context_code_repositories
  PARTITION_SIZE = 2_000_000

  def up
    with_lock_retries do
      create_table TABLE_NAME,
        options: 'PARTITION BY RANGE (project_id)',
        primary_key: [:id, :project_id], if_not_exists: true do |t|
        t.bigserial :id, null: false

        t.bigint :project_id, null: false
        t.bigint :connection_id
        t.bigint :enabled_namespace_id,
          index: { name: 'idx_p_ai_active_context_code_repositories_enabled_namespace_id' }

        t.jsonb :metadata, null: false, default: {}
        t.text :last_commit, limit: 64
        t.integer :state, limit: 2, null: false, default: 0

        t.datetime_with_timezone :indexed_at
        t.timestamps_with_timezone null: false

        t.index [:connection_id, :project_id], unique: true,
          name: 'idx_unique_ai_code_repository_connection_project_id'

        t.index [:project_id, :state],
          name: 'idx_ai_code_repository_project_id_state'
      end
    end

    create_partitions
  end

  def down
    drop_table TABLE_NAME
  end

  private

  def create_partitions
    min_id = Project.connection
      .select_value("select min_value from pg_sequences where sequencename = 'projects_id_seq'") || 1

    max_id = Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
      Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed do
        define_batchable_model('projects', connection: connection).maximum(:id) || min_id
      end
    end

    create_int_range_partitions(TABLE_NAME, PARTITION_SIZE, min_id, max_id)
  end
end
