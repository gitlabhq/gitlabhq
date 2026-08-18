# frozen_string_literal: true

class DropPCiBuildsMetadataTable < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  TABLE_NAME = :p_ci_builds_metadata
  SEQUENCE_NAME = :ci_builds_metadata_id_seq

  def up
    drop_table TABLE_NAME, if_exists: true
  end

  def down
    create_table TABLE_NAME,
      if_not_exists: true,
      options: 'PARTITION BY LIST (partition_id)',
      primary_key: %i[id partition_id] do |t|
      t.bigint :project_id, null: false
      t.integer :timeout
      t.integer :timeout_source, null: false, default: 1
      t.boolean :interruptible
      t.jsonb :config_options
      t.jsonb :config_variables
      t.boolean :has_exposed_artifacts
      t.string :environment_auto_stop_in, limit: 255
      t.string :expanded_environment_name, limit: 255
      t.jsonb :secrets, null: false, default: {}
      t.bigint :build_id, null: false
      t.bigint :id, null: false
      t.jsonb :id_tokens, null: false, default: {}
      t.bigint :partition_id, null: false
      t.boolean :debug_trace_enabled, null: false, default: false
      t.integer :exit_code, limit: 2

      t.index :build_id,
        name: 'p_ci_builds_metadata_build_id_id_idx',
        include: [:id],
        where: 'interruptible = TRUE'
      t.index :build_id,
        name: 'p_ci_builds_metadata_build_id_idx',
        where: 'has_exposed_artifacts IS TRUE'
      t.index %i[build_id partition_id],
        name: 'p_ci_builds_metadata_build_id_partition_id_idx',
        unique: true
      t.index :project_id, name: 'p_ci_builds_metadata_project_id_idx'
    end

    add_sequence TABLE_NAME, :id, SEQUENCE_NAME, 1

    execute <<~SQL
      ALTER SEQUENCE #{quote_table_name(SEQUENCE_NAME)}
      OWNED BY #{quote_table_name(TABLE_NAME)}.#{quote_column_name(:id)}
    SQL
  end
end
