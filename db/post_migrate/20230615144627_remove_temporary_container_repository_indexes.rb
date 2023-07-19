# frozen_string_literal: true

class RemoveTemporaryContainerRepositoryIndexes < Gitlab::Database::Migration[2.1]
  INDEX_CONTAINER_REPOS_ON_NON_MIGRATED = 'tmp_index_container_repos_on_non_migrated'
  INDEX_CONTAINER_REPOSITORIES_ON_ID_MIGRATION_STATE = 'tmp_index_container_repositories_on_id_migration_state'
  INDEX_MIGRATED_CONTAINER_REGISTRIES = 'tmp_index_migrated_container_registries'
  INDEX_CONTAINER_REPOS_ON_IMPORT_STARTED_AT_WHEN_IMPORTING = 'idx_container_repos_on_import_started_at_when_importing'
  INDEX_CONTAINER_REPOS_ON_MIGRATION_STATE_MIGRATION_PLAN_CREATED =
    'idx_container_repos_on_migration_state_migration_plan_created'
  INDEX_CONTAINER_REPOS_ON_PRE_IMPORT_DONE_AT_WHEN_PRE_IMPORT_DONE =
    'idx_container_repos_on_pre_import_done_at_when_pre_import_done'
  INDEX_CONTAINER_REPOS_ON_PRE_IMPORT_STARTED_AT_WHEN_PRE_IMPORTING =
    'idx_container_repos_on_pre_import_started_at_when_pre_importing'
  INDEX_CONTAINER_REPOSITORIES_ON_GREATEST_COMPLETED_AT = 'index_container_repositories_on_greatest_completed_at'
  INDEX_CONTAINER_REPOSITORIES_ON_MIGRATION_STATE_IMPORT_DONE_AT =
    'index_container_repositories_on_migration_state_import_done_at'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :container_repositories, INDEX_CONTAINER_REPOS_ON_NON_MIGRATED
    remove_concurrent_index_by_name :container_repositories, INDEX_CONTAINER_REPOSITORIES_ON_ID_MIGRATION_STATE
    remove_concurrent_index_by_name :container_repositories, INDEX_MIGRATED_CONTAINER_REGISTRIES
    remove_concurrent_index_by_name :container_repositories, INDEX_CONTAINER_REPOS_ON_IMPORT_STARTED_AT_WHEN_IMPORTING
    remove_concurrent_index_by_name :container_repositories,
      INDEX_CONTAINER_REPOS_ON_MIGRATION_STATE_MIGRATION_PLAN_CREATED
    remove_concurrent_index_by_name :container_repositories,
      INDEX_CONTAINER_REPOS_ON_PRE_IMPORT_DONE_AT_WHEN_PRE_IMPORT_DONE
    remove_concurrent_index_by_name :container_repositories,
      INDEX_CONTAINER_REPOS_ON_PRE_IMPORT_STARTED_AT_WHEN_PRE_IMPORTING
    remove_concurrent_index_by_name :container_repositories, INDEX_CONTAINER_REPOSITORIES_ON_GREATEST_COMPLETED_AT
    remove_concurrent_index_by_name :container_repositories,
      INDEX_CONTAINER_REPOSITORIES_ON_MIGRATION_STATE_IMPORT_DONE_AT
  end

  def down
    add_concurrent_index :container_repositories,
      [:project_id, :id],
      name: INDEX_CONTAINER_REPOS_ON_NON_MIGRATED,
      where: "migration_state != 'import_done'"

    add_concurrent_index :container_repositories,
      [:id, :migration_state],
      name: INDEX_CONTAINER_REPOSITORIES_ON_ID_MIGRATION_STATE

    add_concurrent_index :container_repositories,
      [:project_id],
      name: INDEX_MIGRATED_CONTAINER_REGISTRIES,
      where: "migration_state = 'import_done' OR created_at >= '2022-01-23'"

    add_concurrent_index :container_repositories,
      [:migration_import_started_at],
      name: INDEX_CONTAINER_REPOS_ON_IMPORT_STARTED_AT_WHEN_IMPORTING,
      where: "migration_state = 'importing'::text"

    add_concurrent_index :container_repositories,
      [:migration_state, :migration_plan, :created_at],
      name: INDEX_CONTAINER_REPOS_ON_MIGRATION_STATE_MIGRATION_PLAN_CREATED

    add_concurrent_index :container_repositories,
      [:migration_pre_import_done_at],
      name: INDEX_CONTAINER_REPOS_ON_PRE_IMPORT_DONE_AT_WHEN_PRE_IMPORT_DONE,
      where: "migration_state = 'pre_import_done'::text"

    add_concurrent_index :container_repositories,
      [:migration_pre_import_started_at],
      name: INDEX_CONTAINER_REPOS_ON_PRE_IMPORT_STARTED_AT_WHEN_PRE_IMPORTING,
      where: "migration_state = 'pre_importing'::text"

    execute(
      <<-SQL
        CREATE INDEX CONCURRENTLY #{INDEX_CONTAINER_REPOSITORIES_ON_GREATEST_COMPLETED_AT} ON container_repositories
        USING btree (GREATEST(migration_pre_import_done_at, migration_import_done_at, migration_aborted_at, migration_skipped_at))
        WHERE (migration_state = ANY (ARRAY['import_done'::text, 'pre_import_done'::text, 'import_aborted'::text, 'import_skipped'::text]));
      SQL
    )

    add_concurrent_index :container_repositories,
      [:migration_state, :migration_import_done_at],
      name: INDEX_CONTAINER_REPOSITORIES_ON_MIGRATION_STATE_IMPORT_DONE_AT
  end
end
