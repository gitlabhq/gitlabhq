# frozen_string_literal: true

class DropCiRunnerMachinesArchived < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::IndexHelpers
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '18.0'

  disable_ddl_transaction!

  TABLE_NAME = :ci_runner_machines
  ARCHIVED_TABLE_NAME = "#{TABLE_NAME}_archived"

  INDEXES = [
    {
      old_name: :idx_uniq_ci_runner_machines_687967fa8a_on_runner_id_system_xid,
      new_name: :index_ci_runner_machines_on_runner_id_and_type_and_system_xid
    },
    {
      old_name: :idx_ci_runner_machines_687967fa8a_on_contacted_at_desc_id_desc,
      new_name: :index_ci_runner_machines_on_contacted_at_desc_and_id_desc
    },
    {
      old_name: :index_ci_runner_machines_687967fa8a_on_created_at_and_id_desc,
      new_name: :index_ci_runner_machines_on_created_at_and_id_desc
    },
    {
      old_name: :idx_ci_runner_machines_687967fa8a_on_sharding_key_where_notnull,
      new_name: :index_ci_runner_machines_on_sharding_key_id_when_not_null
    },
    {
      old_name: :index_ci_runner_machines_687967fa8a_on_version,
      new_name: :index_ci_runner_machines_on_version
    },
    {
      old_name: :index_ci_runner_machines_687967fa8a_on_major_version,
      new_name: :index_ci_runner_machines_on_major_version_trigram
    },
    {
      old_name: :index_ci_runner_machines_687967fa8a_on_minor_version,
      new_name: :index_ci_runner_machines_on_minor_version_trigram
    },
    {
      old_name: :index_ci_runner_machines_687967fa8a_on_patch_version,
      new_name: :index_ci_runner_machines_on_patch_version_trigram
    }
  ].freeze

  def up
    indexes = indexes_by_definition_for_table(ARCHIVED_TABLE_NAME, schema_name: connection.current_schema)
    indexes = fix_index_names(indexes)

    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- these are just helpers over allowed methods
    with_lock_retries do
      # The archive table will be deleted, not TABLE_NAME
      drop_nonpartitioned_archive_table(TABLE_NAME) if table_exists?(ARCHIVED_TABLE_NAME)
      rename_indexes_for_table(TABLE_NAME, indexes)
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end

  def down
    INDEXES
      .filter { |index| index_exists_by_name?(TABLE_NAME, index[:new_name]) }
      .each do |index|
        with_lock_retries(raise_on_exhaustion: true) do
          rename_index(TABLE_NAME, index[:new_name], index[:old_name])
        end
      end

    recreate_archive_table unless table_exists?(ARCHIVED_TABLE_NAME)
    create_trigger_to_sync_tables(TABLE_NAME, ARCHIVED_TABLE_NAME, :id)
  end

  private

  def recreate_archive_table
    execute <<-SQL
      CREATE TABLE #{ARCHIVED_TABLE_NAME} (
        id bigint NOT NULL,
        runner_id bigint NOT NULL,
        executor_type smallint,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL,
        contacted_at timestamp with time zone,
        version text,
        revision text,
        platform text,
        architecture text,
        ip_address text,
        config jsonb DEFAULT '{}'::jsonb NOT NULL,
        system_xid text,
        creation_state smallint DEFAULT 0 NOT NULL,
        runner_type smallint,
        sharding_key_id bigint,
        runtime_features jsonb DEFAULT '{}'::jsonb NOT NULL,
        CONSTRAINT check_1537c1f66f CHECK ((char_length(platform) <= 255)),
        CONSTRAINT check_5253913ae9 CHECK ((char_length(system_xid) <= 64)),
        CONSTRAINT check_6f45a91da7 CHECK ((char_length(version) <= 2048)),
        CONSTRAINT check_9b521b3105 CHECK ((char_length(architecture) <= 255)),
        CONSTRAINT check_afb8efc1a2 CHECK ((char_length(revision) <= 255)),
        CONSTRAINT check_b714f452d5 CHECK ((system_xid IS NOT NULL)),
        CONSTRAINT check_f214590856 CHECK ((char_length(ip_address) <= 1024))
      );

      ALTER TABLE ONLY #{ARCHIVED_TABLE_NAME}
        ADD CONSTRAINT #{ARCHIVED_TABLE_NAME}_pkey PRIMARY KEY (id);

      CREATE INDEX index_ci_runner_machines_on_contacted_at_desc_and_id_desc ON #{ARCHIVED_TABLE_NAME} USING btree (contacted_at DESC, id DESC);
      CREATE INDEX index_ci_runner_machines_on_created_at_and_id_desc ON #{ARCHIVED_TABLE_NAME} USING btree (created_at, id DESC);
      CREATE INDEX index_ci_runner_machines_on_major_version_trigram ON #{ARCHIVED_TABLE_NAME} USING btree ("substring"(version, '^\\d+\\.'::text), version, runner_id);
      CREATE INDEX index_ci_runner_machines_on_minor_version_trigram ON #{ARCHIVED_TABLE_NAME} USING btree ("substring"(version, '^\\d+\\.\\d+\\.'::text), version, runner_id);
      CREATE INDEX index_ci_runner_machines_on_patch_version_trigram ON #{ARCHIVED_TABLE_NAME} USING btree ("substring"(version, '^\\d+\\.\\d+\\.\\d+'::text), version, runner_id);
      CREATE UNIQUE INDEX index_ci_runner_machines_on_runner_id_and_system_xid ON #{ARCHIVED_TABLE_NAME} USING btree (runner_id, system_xid);
      CREATE INDEX index_ci_runner_machines_on_runner_type ON #{ARCHIVED_TABLE_NAME} USING btree (runner_type);
      CREATE INDEX index_ci_runner_machines_on_sharding_key_id_when_not_null ON #{ARCHIVED_TABLE_NAME} USING btree (sharding_key_id) WHERE (sharding_key_id IS NOT NULL);
      CREATE INDEX index_ci_runner_machines_on_version ON #{ARCHIVED_TABLE_NAME} USING btree (version);
    SQL
  end

  def fix_index_names(indexes)
    indexes.tap do |result|
      # The unique key contains a new column in the partitioned table, let's reflect that in the
      # indexes hash
      # NOTE: Some users needed to delete index_ci_runner_machines_on_runner_id_and_system_xid due to violation of
      # unique key constraint, so let's also ensure the new index is present in order to be renamed.
      # See https://forum.gitlab.com/t/ci-job-pending-after-upgrade-17-8-2-ee-to-7-10-4-ee/124294/4
      result.delete('CREATE UNIQUE _ btree (runner_id, system_xid)')
      indexes['CREATE UNIQUE _ btree (runner_id, runner_type, system_xid)'] =
        'index_ci_runner_machines_on_runner_id_and_type_and_system_xid'
    end
  end
end
