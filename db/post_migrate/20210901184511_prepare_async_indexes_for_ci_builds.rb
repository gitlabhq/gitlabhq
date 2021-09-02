# frozen_string_literal: true

class PrepareAsyncIndexesForCiBuilds < Gitlab::Database::Migration[1.0]
  def up
    prepare_async_index :ci_builds, :stage_id_convert_to_bigint, name: :index_ci_builds_on_converted_stage_id

    prepare_async_index :ci_builds, [:commit_id, :artifacts_expire_at, :id_convert_to_bigint],
      where: "type::text = 'Ci::Build'::text
              AND (retried = false OR retried IS NULL)
              AND (name::text = ANY (ARRAY['sast'::character varying::text,
                                           'secret_detection'::character varying::text,
                                           'dependency_scanning'::character varying::text,
                                           'container_scanning'::character varying::text,
                                           'dast'::character varying::text]))",
      name: :index_ci_builds_on_commit_id_expire_at_and_converted_id

    prepare_async_index :ci_builds, [:project_id, :id_convert_to_bigint],
      name: :index_ci_builds_on_project_and_converted_id

    prepare_async_index :ci_builds, [:runner_id, :id_convert_to_bigint],
      order: { id_convert_to_bigint: :desc },
      name: :index_ci_builds_on_runner_id_and_converted_id_desc

    prepare_async_index :ci_builds, [:resource_group_id, :id_convert_to_bigint],
      where: 'resource_group_id IS NOT NULL',
      name: :index_ci_builds_on_resource_group_and_converted_id

    prepare_async_index :ci_builds, [:name, :id_convert_to_bigint],
      where: "(name::text = ANY (ARRAY['container_scanning'::character varying::text,
                                       'dast'::character varying::text,
                                       'dependency_scanning'::character varying::text,
                                       'license_management'::character varying::text,
                                       'sast'::character varying::text,
                                       'secret_detection'::character varying::text,
                                       'coverage_fuzzing'::character varying::text,
                                       'license_scanning'::character varying::text])
                ) AND type::text = 'Ci::Build'::text",
      name: :index_security_ci_builds_on_name_and_converted_id_parser

    prepare_async_index_from_sql(:ci_builds, :index_ci_builds_runner_id_and_converted_id_pending_covering, <<~SQL.squish)
        CREATE INDEX CONCURRENTLY index_ci_builds_runner_id_and_converted_id_pending_covering
        ON ci_builds (runner_id, id_convert_to_bigint) INCLUDE (project_id)
        WHERE status::text = 'pending'::text AND type::text = 'Ci::Build'::text
    SQL
  end

  def down
    unprepare_async_index_by_name :ci_builds, :index_ci_builds_runner_id_and_converted_id_pending_covering

    unprepare_async_index_by_name :ci_builds, :index_security_ci_builds_on_name_and_converted_id_parser

    unprepare_async_index_by_name :ci_builds, :index_ci_builds_on_resource_group_and_converted_id

    unprepare_async_index_by_name :ci_builds, :index_ci_builds_on_runner_id_and_converted_id_desc

    unprepare_async_index_by_name :ci_builds, :index_ci_builds_on_project_and_converted_id

    unprepare_async_index_by_name :ci_builds, :index_ci_builds_on_commit_id_expire_at_and_converted_id

    unprepare_async_index_by_name :ci_builds, :index_ci_builds_on_converted_stage_id
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
