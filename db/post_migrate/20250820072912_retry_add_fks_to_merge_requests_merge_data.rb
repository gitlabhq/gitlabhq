# frozen_string_literal: true

class RetryAddFksToMergeRequestsMergeData < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.4'

  TABLE_NAME = :merge_requests_merge_data
  FOREIGN_KEYS = [
    {
      column: :merge_request_id,
      target_table: :merge_requests,
      on_delete: :cascade
    },
    {
      column: :project_id,
      target_table: :projects,
      on_delete: :cascade
    },
    {
      column: :merge_user_id,
      target_table: :users,
      on_delete: :nullify
    }
  ].freeze

  def up
    FOREIGN_KEYS.each do |fk|
      fk_name = concurrent_partitioned_foreign_key_name(TABLE_NAME, fk[:column])

      add_concurrent_partitioned_foreign_key TABLE_NAME, fk[:target_table],
        column: fk[:column], on_delete: fk[:on_delete], name: fk_name, validate: false

      prepare_partitioned_async_foreign_key_validation TABLE_NAME, fk[:column], name: fk_name
    end
  end

  def down
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      FOREIGN_KEYS.each do |fk|
        fk_name = concurrent_partitioned_foreign_key_name(TABLE_NAME, fk[:column])

        remove_foreign_key_if_exists partition.identifier, column: fk[:column], name: fk_name
        unprepare_async_foreign_key_validation partition.identifier, fk[:column], name: fk_name
      end
    end
  end

  private

  # NOTE: it seems that prepare_async_foreign_key_validation uses concurrent_foreign_key_name internally which is
  # different from concurrent_partitioned_foreign_key_name used in add_concurrent_partitioned_foreign_key.
  def concurrent_partitioned_foreign_key_name(table, column, prefix: 'fk_rails_')
    identifier = "#{table}_#{column}_fk"
    hashed_identifier = Digest::SHA256.hexdigest(identifier).first(10)

    "#{prefix}#{hashed_identifier}"
  end
end
