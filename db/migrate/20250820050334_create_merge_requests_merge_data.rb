# frozen_string_literal: true

class CreateMergeRequestsMergeData < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.4'

  TABLE_NAME = :merge_requests_merge_data
  SOURCE_TABLE_NAME = 'merge_requests'
  PARTITION_SIZE = 10_000_000
  MIN_ID = 1

  def up
    create_table TABLE_NAME, id: false, options: 'PARTITION BY RANGE (merge_request_id)' do |t|
      t.bigint :merge_request_id, null: false, primary_key: true, default: nil, index: false
      t.bigint :project_id, null: false, index: true
      t.bigint :merge_user_id, index: true
      t.text :merge_params # rubocop:disable Migration/AddLimitToTextColumns -- migrating a legacy column
      t.text :merge_error # rubocop:disable Migration/AddLimitToTextColumns -- migrating a legacy column
      t.text :merge_jid, limit: 255
      t.binary :merge_commit_sha
      t.binary :merged_commit_sha
      t.binary :merge_ref_sha
      t.binary :squash_commit_sha
      t.binary :in_progress_merge_commit_sha
      t.column :merge_status, :smallint, null: false, default: 0
      t.boolean :auto_merge_enabled, null: false, default: false
      t.boolean :squash, null: false, default: false
    end

    create_partitions
  end

  def down
    drop_table TABLE_NAME
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
