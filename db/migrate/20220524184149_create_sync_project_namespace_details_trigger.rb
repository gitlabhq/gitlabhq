# frozen_string_literal: true
class CreateSyncProjectNamespaceDetailsTrigger < Gitlab::Database::Migration[2.0]
  include Gitlab::Database::SchemaHelpers

  UPDATE_TRIGGER_NAME = 'trigger_update_details_on_project_update'
  INSERT_TRIGGER_NAME = 'trigger_update_details_on_project_insert'
  FUNCTION_NAME = 'update_namespace_details_from_projects'

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
              NEW.project_namespace_id
            ) ON CONFLICT (namespace_id) DO
          UPDATE
          SET
            description = NEW.description,
            description_html = NEW.description_html,
            cached_markdown_version = NEW.cached_markdown_version,
            updated_at = NEW.updated_at
          WHERE
            namespace_details.namespace_id = NEW.project_namespace_id;RETURN NULL;
      SQL
    end

    execute(<<~SQL)
        CREATE TRIGGER #{UPDATE_TRIGGER_NAME}
        AFTER UPDATE ON projects
        FOR EACH ROW
        WHEN (
          OLD.description IS DISTINCT FROM NEW.description OR
          OLD.description_html IS DISTINCT FROM NEW.description_html OR
          OLD.cached_markdown_version IS DISTINCT FROM NEW.cached_markdown_version
        )
        EXECUTE PROCEDURE #{FUNCTION_NAME}();
    SQL

    execute(<<~SQL)
        CREATE TRIGGER #{INSERT_TRIGGER_NAME}
        AFTER INSERT ON projects
        FOR EACH ROW
        EXECUTE PROCEDURE #{FUNCTION_NAME}();
    SQL
  end

  def down
    drop_trigger(:projects, UPDATE_TRIGGER_NAME)
    drop_trigger(:projects, INSERT_TRIGGER_NAME)
    drop_function(FUNCTION_NAME)
  end
end
