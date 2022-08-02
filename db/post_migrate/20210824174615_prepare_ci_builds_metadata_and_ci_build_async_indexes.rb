# frozen_string_literal: true

class PrepareCiBuildsMetadataAndCiBuildAsyncIndexes < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    prepare_async_index :ci_builds_metadata, :id_convert_to_bigint, unique: true,
                                                                    name: :index_ci_builds_metadata_on_id_convert_to_bigint

    prepare_async_index :ci_builds_metadata, :build_id_convert_to_bigint, unique: true,
                                                                          name: :index_ci_builds_metadata_on_build_id_convert_to_bigint

    prepare_async_index :ci_builds_metadata, :build_id_convert_to_bigint, where: 'has_exposed_artifacts IS TRUE',
                                                                          name: :index_ci_builds_metadata_on_build_id_int8_and_exposed_artifacts

    prepare_async_index_from_sql(:ci_builds_metadata, :index_ci_builds_metadata_on_build_id_int8_where_interruptible, <<~SQL.squish)
        CREATE INDEX CONCURRENTLY "index_ci_builds_metadata_on_build_id_int8_where_interruptible"
        ON "ci_builds_metadata" ("build_id_convert_to_bigint") INCLUDE ("id_convert_to_bigint")
        WHERE interruptible = true
    SQL

    prepare_async_index :ci_builds, :id_convert_to_bigint, unique: true,
                                                           name: :index_ci_builds_on_converted_id
  end

  def down
    unprepare_async_index_by_name :ci_builds, :index_ci_builds_on_converted_id

    unprepare_async_index_by_name :ci_builds_metadata, :index_ci_builds_metadata_on_build_id_int8_where_interruptible

    unprepare_async_index_by_name :ci_builds_metadata, :index_ci_builds_metadata_on_build_id_int8_and_exposed_artifacts

    unprepare_async_index_by_name :ci_builds_metadata, :index_ci_builds_metadata_on_build_id_convert_to_bigint

    unprepare_async_index_by_name :ci_builds_metadata, :index_ci_builds_metadata_on_id_convert_to_bigint
  end

  private

  def prepare_async_index_from_sql(table_name, index_name, definition)
    return unless async_index_creation_available?

    return if index_name_exists?(table_name, index_name)

    async_index = Gitlab::Database::AsyncIndexes::PostgresAsyncIndex.find_or_create_by!(name: index_name) do |rec|
      rec.table_name = table_name
      rec.definition = definition
    end

    Gitlab::AppLogger.info(
      message: 'Prepared index for async creation',
      table_name: async_index.table_name,
      index_name: async_index.name)
  end
end
