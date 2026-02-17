# frozen_string_literal: true

# rubocop:disable BackgroundMigration/DictionaryFile -- the milestone is already present
class SplitMetadataMigration < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = 'MoveCiBuildsMetadata'
  MIGRATION_ID = 3000518
  MIGRATION_TUPLE_COUNT = 4774979600

  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 250

  PARTITION_NAME = 'gitlab_partitions_dynamic.ci_builds'
  VIEW_PREFIX = 'gitlab_partitions_dynamic.ci_builds_views_100'
  VIEW_BOUNDARIES = [
    1,
    1500384395,
    2951960143,
    4355055910,
    12168556334
  ].freeze

  MIGRATIONS_COUNT = VIEW_BOUNDARIES.size - 1

  def up
    return unless Gitlab.com_except_jh?
    return unless migration_exist?

    queue_migrations_for_views
    update_original_migration
    update_tuple_stats
  end

  def down
    return unless Gitlab.com_except_jh?
    return unless migration_exist?("#{VIEW_PREFIX}_1")

    delete_all_view_migrations
    restore_original_migration
  end

  private

  def queue_migrations_for_views
    VIEW_BOUNDARIES.each_cons(2).map.with_index(1) do |range, view_number|
      next if view_number == 1

      queue_batched_background_migration(
        MIGRATION,
        "#{VIEW_PREFIX}_#{view_number}",
        :id,
        :partition_id,
        [100],
        batch_size: BATCH_SIZE,
        sub_batch_size: SUB_BATCH_SIZE,
        batch_min_value: range.first,
        batch_max_value: range.last
      )
    end
  end

  def update_original_migration
    Gitlab::Database::BackgroundMigration::BatchedMigration
      .where(id: MIGRATION_ID)
      .update_all(
        table_name: "#{VIEW_PREFIX}_1",
        max_value: VIEW_BOUNDARIES[1]
      )
  end

  def update_tuple_stats
    Gitlab::Database::BackgroundMigration::BatchedMigration
      .where(job_class_name: MIGRATION)
      .where(table_name: 1.upto(MIGRATIONS_COUNT).map { |i| "#{VIEW_PREFIX}_#{i}" })
      .update_all(total_tuple_count: MIGRATION_TUPLE_COUNT / MIGRATIONS_COUNT)
  end

  def delete_all_view_migrations
    2.upto(MIGRATIONS_COUNT) do |view_number|
      delete_batched_background_migration(MIGRATION, "#{VIEW_PREFIX}_#{view_number}", 'id', ['partition_id', [100]])
    end
  end

  def restore_original_migration
    Gitlab::Database::BackgroundMigration::BatchedMigration
      .where(id: MIGRATION_ID)
      .update_all(
        table_name: PARTITION_NAME,
        max_value: VIEW_BOUNDARIES.last,
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
