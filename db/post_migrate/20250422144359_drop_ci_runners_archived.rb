# frozen_string_literal: true

class DropCiRunnersArchived < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::IndexHelpers
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '18.0'

  disable_ddl_transaction!

  TABLE_NAME = :ci_runners
  ARCHIVED_TABLE_NAME = "#{TABLE_NAME}_archived"

  INDEXES = [
    {
      old_name: :idx_uniq_ci_runners_e59bb2812d_on_token_and_type_where_not_null,
      new_name: :index_ci_runners_on_token_and_runner_type_when_token_not_null
    },
    {
      old_name: :index_uniq_ci_runners_e59bb2812d_on_token_encrypted_and_type,
      new_name: :index_ci_runners_on_token_encrypted_and_runner_type
    },
    { old_name: :index_ci_runners_e59bb2812d_on_active_and_id, new_name: :index_ci_runners_on_active_and_id },
    {
      old_name: :index_ci_runners_e59bb2812d_on_contacted_at_and_id_desc,
      new_name: :index_ci_runners_on_contacted_at_and_id_desc
    },
    {
      old_name: :idx_ci_runners_e59bb2812d_on_contacted_at_and_id_where_inactive,
      new_name: :index_ci_runners_on_contacted_at_and_id_where_inactive
    },
    {
      old_name: :index_ci_runners_e59bb2812d_on_contacted_at_desc_and_id_desc,
      new_name: :index_ci_runners_on_contacted_at_desc_and_id_desc
    },
    {
      old_name: :index_ci_runners_e59bb2812d_on_created_at_and_id_desc,
      new_name: :index_ci_runners_on_created_at_and_id_desc
    },
    {
      old_name: :index_ci_runners_e59bb2812d_on_created_at_and_id_where_inactive,
      new_name: :index_ci_runners_on_created_at_and_id_where_inactive
    },
    {
      old_name: :index_ci_runners_e59bb2812d_on_created_at_desc_and_id_desc,
      new_name: :index_ci_runners_on_created_at_desc_and_id_desc
    },
    {
      old_name: :index_ci_runners_e59bb2812d_on_creator_id_where_not_null,
      new_name: :index_ci_runners_on_creator_id_where_creator_id_not_null
    },
    {
      old_name: :index_ci_runners_e59bb2812d_on_description_trigram,
      new_name: :index_ci_runners_on_description_trigram
    },
    {
      old_name: :index_ci_runners_e59bb2812d_on_locked,
      new_name: :index_ci_runners_on_locked
    },
    {
      old_name: :index_ci_runners_e59bb2812d_on_sharding_key_id_where_not_null,
      new_name: :index_ci_runners_on_sharding_key_id_when_not_null
    },
    {
      old_name: :index_ci_runners_e59bb2812d_on_token_expires_at_and_id_desc,
      new_name: :index_ci_runners_on_token_expires_at_and_id_desc
    },
    {
      old_name: :idx_ci_runners_e59bb2812d_on_token_expires_at_desc_and_id_desc,
      new_name: :index_ci_runners_on_token_expires_at_desc_and_id_desc
    }
  ].freeze

  FOREIGN_KEY_CHECKS = [
    { table_name: 'ci_runner_projects', constraint_name: 'fk_0e743433ff' },
    { table_name: 'ci_instance_runner_monthly_usages', constraint_name: 'fk_rails_38b9dcccc9', on_delete: :nullify },
    { table_name: 'ci_running_builds', constraint_name: 'fk_rails_5ca491d360' },
    { table_name: 'ci_runner_machines_archived', constraint_name: 'fk_rails_666b61f04f' },
    { table_name: 'ci_cost_settings', constraint_name: 'fk_rails_6a70651f75' },
    { table_name: 'ci_runner_namespaces', constraint_name: 'fk_rails_8767676b7a' }
  ].freeze

  def up
    FOREIGN_KEY_CHECKS.each do |check|
      with_lock_retries(raise_on_exhaustion: true) do
        remove_foreign_key_if_exists(check[:table_name], name: check[:constraint_name])
      end
    end

    indexes = indexes_by_definition_for_table(ARCHIVED_TABLE_NAME, schema_name: connection.current_schema)
    indexes = fix_index_names(indexes)

    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- these are just helpers over allowed methods
    with_lock_retries do
      drop_nonpartitioned_archive_table(TABLE_NAME)
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
    execute(<<-SQL)
      CREATE TABLE #{ARCHIVED_TABLE_NAME} (
        id bigint NOT NULL,
        token character varying,
        created_at timestamp without time zone,
        updated_at timestamp without time zone,
        description character varying,
        contacted_at timestamp without time zone,
        active boolean DEFAULT true NOT NULL,
        name character varying,
        run_untagged boolean DEFAULT true NOT NULL,
        locked boolean DEFAULT false NOT NULL,
        access_level integer DEFAULT 0 NOT NULL,
        maximum_timeout integer,
        runner_type smallint NOT NULL,
        token_encrypted character varying,
        public_projects_minutes_cost_factor double precision DEFAULT 1.0 NOT NULL,
        private_projects_minutes_cost_factor double precision DEFAULT 1.0 NOT NULL,
        maintainer_note text,
        token_expires_at timestamp with time zone,
        allowed_plans text[] DEFAULT '{}'::text[] NOT NULL,
        registration_type smallint DEFAULT 0 NOT NULL,
        creator_id bigint,
        creation_state smallint DEFAULT 0 NOT NULL,
        allowed_plan_ids bigint[] DEFAULT '{}'::bigint[] NOT NULL,
        sharding_key_id bigint,
        CONSTRAINT check_46c685e76f CHECK ((char_length((description)::text) <= 1024)),
        CONSTRAINT check_91230910ec CHECK ((char_length((name)::text) <= 256)),
        CONSTRAINT check_ce275cee06 CHECK ((char_length(maintainer_note) <= 1024))
      );

      ALTER TABLE ONLY #{ARCHIVED_TABLE_NAME} ADD CONSTRAINT #{ARCHIVED_TABLE_NAME}_pkey PRIMARY KEY (id);

      CREATE INDEX index_ci_runners_on_active ON #{ARCHIVED_TABLE_NAME} USING btree (active, id);
      CREATE INDEX index_ci_runners_on_contacted_at_and_id_desc ON #{ARCHIVED_TABLE_NAME}
        USING btree (contacted_at, id DESC);
      CREATE INDEX index_ci_runners_on_contacted_at_and_id_where_inactive ON #{ARCHIVED_TABLE_NAME}
        USING btree (contacted_at DESC, id DESC) WHERE (active = false);
      CREATE INDEX index_ci_runners_on_contacted_at_desc_and_id_desc ON #{ARCHIVED_TABLE_NAME}
        USING btree (contacted_at DESC, id DESC);
      CREATE INDEX index_ci_runners_on_created_at_and_id_desc ON #{ARCHIVED_TABLE_NAME}
        USING btree (created_at, id DESC);
      CREATE INDEX index_ci_runners_on_created_at_and_id_where_inactive ON #{ARCHIVED_TABLE_NAME}
        USING btree (created_at DESC, id DESC) WHERE (active = false);
      CREATE INDEX index_ci_runners_on_created_at_desc_and_id_desc ON #{ARCHIVED_TABLE_NAME}
        USING btree (created_at DESC, id DESC);
      CREATE INDEX index_ci_runners_on_creator_id_where_creator_id_not_null ON #{ARCHIVED_TABLE_NAME}
        USING btree (creator_id) WHERE (creator_id IS NOT NULL);
      CREATE INDEX index_ci_runners_on_description_trigram ON #{ARCHIVED_TABLE_NAME}
        USING gin (description gin_trgm_ops);
      CREATE INDEX index_ci_runners_on_locked ON #{ARCHIVED_TABLE_NAME} USING btree (locked);
      CREATE INDEX index_ci_runners_on_runner_type_and_id ON #{ARCHIVED_TABLE_NAME} USING btree (runner_type, id);
      CREATE INDEX index_ci_runners_on_sharding_key_id_when_not_null ON #{ARCHIVED_TABLE_NAME}
        USING btree (sharding_key_id) WHERE (sharding_key_id IS NOT NULL);
      CREATE INDEX index_ci_runners_on_token_expires_at_and_id_desc ON #{ARCHIVED_TABLE_NAME}
        USING btree (token_expires_at, id DESC);
      CREATE INDEX index_ci_runners_on_token_expires_at_desc_and_id_desc ON #{ARCHIVED_TABLE_NAME}
        USING btree (token_expires_at DESC, id DESC);
      CREATE UNIQUE INDEX index_uniq_ci_runners_on_token ON #{ARCHIVED_TABLE_NAME} USING btree (token);
      CREATE UNIQUE INDEX index_uniq_ci_runners_on_token_encrypted ON #{ARCHIVED_TABLE_NAME}
        USING btree (token_encrypted);
    SQL

    # Add foreign key constraints
    FOREIGN_KEY_CHECKS.each do |check|
      add_concurrent_foreign_key(check[:table_name], ARCHIVED_TABLE_NAME, column: :runner_id,
        name: check[:constraint_name], on_delete: check.fetch(:on_delete, :cascade))
    end

    with_lock_retries do
      create_trigger_to_sync_tables(TABLE_NAME, ARCHIVED_TABLE_NAME, 'id')
    end
  end

  def fix_index_names(indexes)
    indexes.dup.tap do |result|
      # Improve name of index_ci_runners_on_active to reflect new column
      if indexes['CREATE _ btree (active, id)'] == 'index_ci_runners_on_active'
        result['CREATE _ btree (active, id)'] = 'index_ci_runners_on_active_and_id'
      end

      # The unique keys contain a new column in the partitioned table, let's reflect that in the indexes hash
      if indexes['CREATE UNIQUE _ btree (token)'] == 'index_uniq_ci_runners_on_token'
        result.delete('CREATE UNIQUE _ btree (token)')
        result['CREATE UNIQUE _ btree (token, runner_type) WHERE (token IS NOT NULL)'] =
          'index_ci_runners_on_token_and_runner_type_when_token_not_null'
      end

      if indexes['CREATE UNIQUE _ btree (token_encrypted)'] == 'index_uniq_ci_runners_on_token_encrypted'
        result.delete('CREATE UNIQUE _ btree (token_encrypted)')
        result['CREATE UNIQUE _ btree (token_encrypted, runner_type)'] =
          'index_ci_runners_on_token_encrypted_and_runner_type'
      end
    end
  end
end
