# frozen_string_literal: true

# Phase 4, wave 1 of https://gitlab.com/gitlab-org/gitlab/-/work_items/597949: routes deleted
# rows of small LFK parent tables to the deleted-records table of their sharding key.
# The parents use the standard trigger form today and the existing partitions the
# override-table form, so `down` restores each as is.
class TrackDeletionsWithShardingKeysWave1 < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  disable_ddl_transaction!
  milestone '19.5'

  TABLES = %i[
    ai_conversation_threads
    approval_policy_rules
    chat_names
    ci_secure_files
    ci_triggers
    cluster_agents
    dependency_proxy_blobs
    packages_debian_project_component_files
    packages_nuget_symbols
    pool_repositories
    push_rules
    security_policies
    slsa_attestations
    terraform_state_versions
    virtual_registries_container_upstreams
    virtual_registries_packages_maven_upstreams
    virtual_registries_packages_npm_upstreams
    work_item_custom_types
  ].freeze

  PARTITIONED_TABLES = %i[
    p_ai_active_context_code_enabled_namespaces
  ].freeze

  def up
    TABLES.each do |table|
      with_lock_retries { track_record_deletions_with_sharding_keys(table) }
    end

    PARTITIONED_TABLES.each do |table|
      with_lock_retries { track_record_deletions_override_table_name_with_sharding_keys(table) }

      each_partition(table) do |partition|
        with_lock_retries { track_record_deletions_override_table_name_with_sharding_keys(partition, table) }
      end
    end
  end

  def down
    (TABLES + PARTITIONED_TABLES).each do |table|
      with_lock_retries do
        execute(<<~SQL.squish)
          CREATE OR REPLACE TRIGGER #{table}_loose_fk_trigger
          AFTER DELETE ON #{table} REFERENCING OLD TABLE AS old_table
          FOR EACH STATEMENT
          EXECUTE FUNCTION #{INSERT_FUNCTION_NAME}();
        SQL
      end
    end

    PARTITIONED_TABLES.each do |table|
      each_partition(table) do |partition|
        with_lock_retries do
          execute(<<~SQL.squish)
            CREATE OR REPLACE TRIGGER #{record_deletion_trigger_name(partition)}
            AFTER DELETE ON #{partition} REFERENCING OLD TABLE AS old_table
            FOR EACH STATEMENT
            EXECUTE FUNCTION #{INSERT_FUNCTION_NAME_OVERRIDE_TABLE}(#{connection.quote(table.to_s)});
          SQL
        end
      end
    end
  end

  private

  def each_partition(table)
    Gitlab::Database::PostgresPartition.for_parent_table(table.to_s).each do |partition|
      yield partition.identifier
    end
  end
end
