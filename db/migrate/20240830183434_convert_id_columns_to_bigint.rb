# frozen_string_literal: true

class ConvertIdColumnsToBigint < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::SchemaHelpers

  milestone '17.4'

  disable_ddl_transaction!

  INT_COL_IN_TRIGGER_DEFINITION = [
    %w[namespaces traversal_ids],
    %w[integrations project_id],
    %w[projects namespace_id]
  ].freeze

  RENAMED_PARTITION_INDEX_MAP = {
    ci_builds_metadata: [
      {
        old_name: :ci_builds_metadata_project_id_idx,
        new_name: :index_ci_builds_metadata_on_project_id
      }
    ],
    ci_stages: [
      {
        old_name: :ci_stages_project_id_idx,
        new_name: :index_ci_stages_on_project_id
      }
    ],
    ci_job_artifacts: [
      {
        old_name: :ci_job_artifacts_file_type_project_id_created_at_idx,
        new_name: :index_ci_job_artifacts_on_file_type_for_devops_adoption
      },
      {
        old_name: :ci_job_artifacts_project_id_created_at_id_idx,
        new_name: :index_ci_job_artifacts_on_id_project_id_and_created_at
      },
      {
        old_name: :ci_job_artifacts_project_id_file_type_id_idx,
        new_name: :index_ci_job_artifacts_on_id_project_id_and_file_type
      },
      {
        old_name: :ci_job_artifacts_project_id_id_idx,
        new_name: :index_ci_job_artifacts_for_terraform_reports
      },
      {
        old_name: :ci_job_artifacts_project_id_id_idx1,
        new_name: :index_ci_job_artifacts_on_project_id_and_id
      },
      {
        old_name: :ci_job_artifacts_project_id_idx,
        new_name: :index_ci_job_artifacts_on_project_id_for_security_reports
      }
    ],
    ci_pipelines: [
      {
        old_name: :ci_pipelines_merge_request_id_idx,
        new_name: :index_ci_pipelines_on_merge_request_id
      },
      {
        old_name: :ci_pipelines_pipeline_schedule_id_id_idx,
        new_name: :index_ci_pipelines_on_pipeline_schedule_id_and_id
      },
      {
        old_name: :ci_pipelines_project_id_id_idx,
        new_name: :index_ci_pipelines_on_project_id_and_id_desc
      },
      {
        old_name: :ci_pipelines_project_id_iid_partition_id_idx,
        new_name: :index_ci_pipelines_on_project_id_and_iid_and_partition_id
      },
      {
        old_name: :ci_pipelines_project_id_ref_status_id_idx,
        new_name: :index_ci_pipelines_on_project_id_and_ref_and_status_and_id
      },
      {
        old_name: :ci_pipelines_project_id_sha_idx,
        new_name: :index_ci_pipelines_on_project_id_and_sha
      },
      {
        old_name: :ci_pipelines_project_id_source_idx,
        new_name: :index_ci_pipelines_on_project_id_and_source
      },
      {
        old_name: :ci_pipelines_project_id_status_config_source_idx,
        new_name: :index_ci_pipelines_on_project_id_and_status_and_config_source
      },
      {
        old_name: :ci_pipelines_project_id_status_created_at_idx,
        new_name: :index_ci_pipelines_on_project_id_and_status_and_created_at
      },
      {
        old_name: :ci_pipelines_project_id_status_updated_at_idx,
        new_name: :index_ci_pipelines_on_project_id_and_status_and_updated_at
      },
      {
        old_name: :ci_pipelines_project_id_user_id_status_ref_idx,
        new_name: :index_ci_pipelines_on_project_id_and_user_id_and_status_and_ref
      },
      {
        old_name: :ci_pipelines_project_id_ref_id_idx,
        new_name: :index_ci_pipelines_on_project_idandrefandiddesc
      },
      {
        old_name: :ci_pipelines_user_id_created_at_config_source_idx,
        new_name: :index_ci_pipelines_on_user_id_and_created_at_and_config_source
      },
      {
        old_name: :ci_pipelines_user_id_created_at_source_idx,
        new_name: :index_ci_pipelines_on_user_id_and_created_at_and_source
      },
      {
        old_name: :ci_pipelines_user_id_id_idx,
        new_name: :index_ci_pipelines_on_user_id_and_id_and_cancelable_status
      },
      {
        old_name: :ci_pipelines_user_id_id_idx1,
        new_name: :index_ci_pipelines_on_user_id_and_id_desc_and_user_not_verified
      }
    ]
  }.freeze

  def up
    return unless Gitlab.dev_or_test_env?

    suppress_messages do
      connection
        .select_rows(find_all_id_columns_sql)
        .each do |table_name, column_name, data_type, column_default|
          convert_column(table_name, column_name, data_type, column_default)
        end

      update_next_traversal_ids_sibling_function
      restore_index_names
    end
  end

  def down
    # no-op
  end

  private

  def convert_column(table_name, column_name, data_type, column_default)
    # For columns that are part of trigger definition, we need to drop the trigger
    # in order to change the type, and then restore the trigger.
    if INT_COL_IN_TRIGGER_DEFINITION.include?([table_name, column_name])
      send(:"convert_#{table_name}_#{column_name}")
    else
      new_data_type = 'bigint'
      new_data_type += '[]' if data_type == 'ARRAY'

      set_default = (", ALTER COLUMN #{column_name} SET DEFAULT '{}'::bigint[]" if column_default == "'{}'::integer[]")

      execute("ALTER TABLE public.#{table_name} ALTER COLUMN #{column_name} TYPE #{new_data_type}#{set_default}")
    end
  end

  def convert_namespaces_traversal_ids
    execute('DROP TRIGGER trigger_namespaces_traversal_ids_on_update ON namespaces')

    execute(
      <<~SQL.strip
        ALTER TABLE namespaces
        ALTER COLUMN traversal_ids TYPE bigint[],
        ALTER COLUMN traversal_ids SET DEFAULT '{}'::bigint[]
      SQL
    )

    create_trigger(:namespaces, :trigger_namespaces_traversal_ids_on_update, :insert_namespaces_sync_event,
      fires: 'AFTER UPDATE') do
      'WHEN (old.traversal_ids IS DISTINCT FROM new.traversal_ids)'
    end
  end

  def convert_integrations_project_id
    execute("DROP TRIGGER trigger_has_external_issue_tracker_on_delete ON integrations")
    execute("DROP TRIGGER trigger_has_external_issue_tracker_on_insert ON integrations")
    execute("DROP TRIGGER trigger_has_external_issue_tracker_on_update ON integrations")
    execute("DROP TRIGGER trigger_has_external_wiki_on_delete ON integrations")
    execute("DROP TRIGGER trigger_has_external_wiki_on_insert ON integrations")
    execute("DROP TRIGGER trigger_has_external_wiki_on_type_new_updated ON integrations")
    execute("DROP TRIGGER trigger_has_external_wiki_on_update ON integrations")

    execute('ALTER TABLE integrations ALTER COLUMN project_id TYPE bigint')

    create_trigger(:integrations, :trigger_has_external_issue_tracker_on_delete, :set_has_external_issue_tracker,
      fires: 'AFTER DELETE') do
      "WHEN (old.category::text = 'issue_tracker'::text AND old.active = true AND old.project_id IS NOT NULL)"
    end
    create_trigger(:integrations, :trigger_has_external_issue_tracker_on_insert, :set_has_external_issue_tracker,
      fires: 'AFTER INSERT') do
      "WHEN (new.category::text = 'issue_tracker'::text AND new.active = true AND new.project_id IS NOT NULL)"
    end
    create_trigger(:integrations, :trigger_has_external_issue_tracker_on_update, :set_has_external_issue_tracker,
      fires: 'AFTER UPDATE') do
      "WHEN (new.category::text = 'issue_tracker'::text AND old.active <> new.active AND new.project_id IS NOT NULL)"
    end
    create_trigger(:integrations, :trigger_has_external_wiki_on_delete, :set_has_external_wiki,
      fires: 'AFTER DELETE') do
      "WHEN (old.type_new = 'Integrations::ExternalWiki'::text AND old.project_id IS NOT NULL)"
    end
    create_trigger(:integrations, :trigger_has_external_wiki_on_insert, :set_has_external_wiki,
      fires: 'AFTER INSERT') do
      "WHEN (new.active = true AND new.type_new = 'Integrations::ExternalWiki'::text AND new.project_id IS NOT NULL)"
    end
    create_trigger(:integrations, :trigger_has_external_wiki_on_type_new_updated, :set_has_external_wiki,
      fires: 'AFTER UPDATE OF type_new') do
      "WHEN (new.type_new = 'Integrations::ExternalWiki'::text AND new.project_id IS NOT NULL)"
    end
    create_trigger(:integrations, :trigger_has_external_wiki_on_update, :set_has_external_wiki,
      fires: 'AFTER UPDATE') do
      <<~SQL.strip
        WHEN (new.type_new = 'Integrations::ExternalWiki'::text AND old.active <> new.active
        AND new.project_id IS NOT NULL)
      SQL
    end
  end

  def convert_projects_namespace_id
    execute('DROP TRIGGER trigger_projects_parent_id_on_update ON projects')

    execute('ALTER TABLE projects ALTER COLUMN namespace_id TYPE bigint')

    create_trigger(:projects, :trigger_projects_parent_id_on_update, :insert_projects_sync_event,
      fires: 'AFTER UPDATE') do
      "WHEN (old.namespace_id IS DISTINCT FROM new.namespace_id)"
    end
  end

  def update_next_traversal_ids_sibling_function
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION next_traversal_ids_sibling(traversal_ids bigint[]) RETURNS bigint[]
          LANGUAGE plpgsql IMMUTABLE STRICT
          AS $$
      BEGIN
        return traversal_ids[1:array_length(traversal_ids, 1)-1] ||
        ARRAY[traversal_ids[array_length(traversal_ids, 1)]+1];
      END;
      $$
    SQL

    execute(<<~SQL)
      DROP FUNCTION IF EXISTS next_traversal_ids_sibling(integer[])
    SQL
  end

  # When the type is changed, all indexes on the column are recreated for partitions
  # and PostgreSQL is generating different names than what we already have.
  # So we have to rename these indexes to restore original names.
  def restore_index_names
    RENAMED_PARTITION_INDEX_MAP.each do |table_name, renamed_indexes|
      renamed_indexes.each do |renamed_index|
        next unless index_name_exists?(table_name, renamed_index[:old_name])

        rename_index(table_name, renamed_index[:old_name], renamed_index[:new_name])
      end
    end
  end
end
