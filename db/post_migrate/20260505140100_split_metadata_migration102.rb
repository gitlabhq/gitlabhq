# frozen_string_literal: true

# rubocop:disable BackgroundMigration/DictionaryFile -- the milestone is already present
class SplitMetadataMigration102 < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = 'MoveCiBuildsMetadata'
  MIGRATION_ID = 3000520
  MIGRATION_TUPLE_COUNT = 2454782500

  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 250

  PARTITION_NAME = 'gitlab_partitions_dynamic.ci_builds_102'
  VIEW_PREFIX = 'gitlab_partitions_dynamic.ci_builds_views_102'

  VIEW_BOUNDARY = 9345589511
  VIEW_MAX_VALUE = 12168598399

  VIEW_1_TUPLE_COUNT = (MIGRATION_TUPLE_COUNT * 0.8).to_i
  VIEW_2_TUPLE_COUNT = MIGRATION_TUPLE_COUNT - VIEW_1_TUPLE_COUNT

  def up
    return unless Gitlab.com_except_jh?
    return unless migration_exist?

    queue_view_2_migration
    update_original_migration
  end

  def down
    return unless Gitlab.com_except_jh?
    return unless migration_exist?("#{VIEW_PREFIX}_1")

    delete_view_2_migration
    restore_original_migration
  end

  private

  def queue_view_2_migration
    queue_batched_background_migration(
      MIGRATION,
      "#{VIEW_PREFIX}_2",
      :id,
      :partition_id,
      [102],
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      batch_min_value: VIEW_BOUNDARY,
      batch_max_value: VIEW_MAX_VALUE
    )

    Gitlab::Database::BackgroundMigration::BatchedMigration
      .where(job_class_name: MIGRATION, table_name: "#{VIEW_PREFIX}_2")
      .update_all(total_tuple_count: VIEW_2_TUPLE_COUNT)
  end

  def update_original_migration
    Gitlab::Database::BackgroundMigration::BatchedMigration
      .where(id: MIGRATION_ID)
      .update_all(
        table_name: "#{VIEW_PREFIX}_1",
        max_value: VIEW_BOUNDARY,
        total_tuple_count: VIEW_1_TUPLE_COUNT
      )
  end

  def delete_view_2_migration
    delete_batched_background_migration(MIGRATION, "#{VIEW_PREFIX}_2", 'id', ['partition_id', [102]])
  end

  def restore_original_migration
    Gitlab::Database::BackgroundMigration::BatchedMigration
      .where(id: MIGRATION_ID)
      .update_all(
        table_name: PARTITION_NAME,
        max_value: VIEW_MAX_VALUE,
        total_tuple_count: MIGRATION_TUPLE_COUNT
      )
  end

  def migration_exist?(table_name = PARTITION_NAME)
    Gitlab::Database::BackgroundMigration::BatchedMigration
      .where(id: MIGRATION_ID, job_class_name: MIGRATION)
      .where(table_name: table_name, status: 1)
      .exists?
  end

  # Workaround to allow a single migration to enqueue multiple background migrations
  def assign_attributes_safely(migration, max_batch_size, batch_table_name, gitlab_schema, _queued_migration_version)
    super(migration, max_batch_size, batch_table_name, gitlab_schema, nil)
  end
end
# rubocop:enable BackgroundMigration/DictionaryFile
