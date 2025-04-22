# frozen_string_literal: true

class CreateMergeRequestCommitsMetadata < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.0'

  TABLE_NAME = :merge_request_commits_metadata
  SOURCE_TABLE_NAME = 'projects'
  PARTITION_SIZE = 2_000_000
  MIN_ID = 1

  # rubocop:disable Migration/EnsureFactoryForTable, Lint/RedundantCopDisableDirective -- False positive
  def up
    unless table_exists?(TABLE_NAME)
      create_table TABLE_NAME,
        options: 'PARTITION BY RANGE(project_id)',
        primary_key: [:id, :project_id] do |t|
        # rubocop:disable Migration/Datetime -- We are keeping it the same with
        # `merge_request_diff_commits` wherein they are timestamps without timezone
        t.datetime :authored_date
        t.datetime :committed_date
        # rubocop:enable Migration/Datetime

        t.bigserial :id, null: false
        t.bigserial :project_id, null: false
        t.bigserial :commit_author_id
        t.bigserial :committer_id

        t.binary :sha, null: false

        # rubocop:disable Migration/AddLimitToTextColumns -- We are keeping it the
        # same with `merge_request_diff_commits` wherein message has no limit
        t.text :message
        # rubocop:enable Migration/AddLimitToTextColumns

        t.jsonb :trailers, null: false, default: {}
        t.index [:project_id, :sha], unique: true
      end
    end

    create_partitions
  end
  # rubocop:enable Migration/EnsureFactoryForTable, Lint/RedundantCopDisableDirective

  def down
    drop_table :merge_request_commits_metadata
  end

  private

  def create_partitions
    max_id = Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
      Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed do
        define_batchable_model(SOURCE_TABLE_NAME, connection: connection).maximum(:id) || MIN_ID
      end
    end

    create_int_range_partitions(TABLE_NAME, PARTITION_SIZE, MIN_ID, max_id)
  end
end
