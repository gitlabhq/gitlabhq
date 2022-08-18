# frozen_string_literal: true
class CreateSyncNamespaceDetailsTrigger < Gitlab::Database::Migration[2.0]
  include Gitlab::Database::SchemaHelpers

  UPDATE_TRIGGER_NAME = 'trigger_update_details_on_namespace_update'
  INSERT_TRIGGER_NAME = 'trigger_update_details_on_namespace_insert'
  FUNCTION_NAME = 'update_namespace_details_from_namespaces'

  enable_lock_retries!

  def up
    create_trigger_function(FUNCTION_NAME, replace: true) do
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
        CREATE TRIGGER #{UPDATE_TRIGGER_NAME}
        AFTER UPDATE ON namespaces
        FOR EACH ROW
        WHEN (
          NEW.type <> 'Project' AND (
          OLD.description IS DISTINCT FROM NEW.description OR
          OLD.description_html IS DISTINCT FROM NEW.description_html OR
          OLD.cached_markdown_version IS DISTINCT FROM NEW.cached_markdown_version)
        )
        EXECUTE PROCEDURE #{FUNCTION_NAME}();
    SQL

    execute(<<~SQL)
        CREATE TRIGGER #{INSERT_TRIGGER_NAME}
        AFTER INSERT ON namespaces
        FOR EACH ROW
        WHEN (NEW.type <> 'Project')
        EXECUTE PROCEDURE #{FUNCTION_NAME}();
    SQL
  end

  def down
    drop_trigger(:namespaces, UPDATE_TRIGGER_NAME)
    drop_trigger(:namespaces, INSERT_TRIGGER_NAME)
    drop_function(FUNCTION_NAME)
  end
end
