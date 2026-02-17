# frozen_string_literal: true

class DropNamespaceDetailsSyncTriggers < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  disable_ddl_transaction!

  NAMESPACE_UPDATE_TRIGGER_NAME = 'trigger_update_details_on_namespace_update'
  NAMESPACE_INSERT_TRIGGER_NAME = 'trigger_update_details_on_namespace_insert'
  NAMESPACE_FUNCTION_NAME = 'update_namespace_details_from_namespaces'

  milestone '18.9'

  def up
    drop_trigger(:namespaces, NAMESPACE_UPDATE_TRIGGER_NAME)
    drop_trigger(:namespaces, NAMESPACE_INSERT_TRIGGER_NAME)
    drop_function(NAMESPACE_FUNCTION_NAME)
  end

  def down
    create_trigger_function(NAMESPACE_FUNCTION_NAME, replace: true) do
      <<~SQL
        INSERT INTO
          namespace_details (
            description,
            description_html,
            cached_markdown_version,
            updated_at,
            created_at,
            namespace_id
          )
        VALUES
          (
            NEW.description,
            NEW.description_html,
            NEW.cached_markdown_version,
            NEW.updated_at,
            NEW.updated_at,
            NEW.id
          ) ON CONFLICT (namespace_id) DO
        UPDATE
        SET
          description = NEW.description,
          description_html = NEW.description_html,
          cached_markdown_version = NEW.cached_markdown_version,
          updated_at = NEW.updated_at
        WHERE
          namespace_details.namespace_id = NEW.id;RETURN NULL;
      SQL
    end

    execute(<<~SQL)
      CREATE TRIGGER #{NAMESPACE_UPDATE_TRIGGER_NAME}
      AFTER UPDATE ON namespaces
      FOR EACH ROW
      WHEN (
        (NEW.type)::text <> 'Project'::text AND (
        (OLD.description)::text IS DISTINCT FROM (NEW.description)::text OR
        OLD.description_html IS DISTINCT FROM NEW.description_html OR
        OLD.cached_markdown_version IS DISTINCT FROM NEW.cached_markdown_version)
      )
      EXECUTE FUNCTION #{NAMESPACE_FUNCTION_NAME}();
    SQL

    execute(<<~SQL)
      CREATE TRIGGER #{NAMESPACE_INSERT_TRIGGER_NAME}
      AFTER INSERT ON namespaces
      FOR EACH ROW
      WHEN ((NEW.type)::text <> 'Project'::text)
      EXECUTE FUNCTION #{NAMESPACE_FUNCTION_NAME}();
    SQL
  end
end
