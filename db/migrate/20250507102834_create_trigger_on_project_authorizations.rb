# frozen_string_literal: true

class CreateTriggerOnProjectAuthorizations < Gitlab::Database::Migration[2.3]
  include ::Gitlab::Database::SchemaHelpers

  milestone '18.0'

  SRC_TABLE = 'project_authorizations'
  DEST_TABLE = 'project_authorizations_for_migration'
  TRIGGER_NAME = 'sync_project_authorizations_to_migration'
  FUNCTION_NAME = 'sync_project_authorizations_to_migration_table'
  FUNCTION_BODY = <<~SQL
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
      INSERT INTO #{DEST_TABLE} (project_id, user_id, access_level)
      VALUES (NEW.project_id, NEW.user_id, NEW.access_level::smallint)
      ON CONFLICT (project_id, user_id) DO UPDATE
        SET access_level = NEW.access_level::smallint;
      RETURN NEW;

    ELSIF (TG_OP = 'DELETE') THEN
      DELETE FROM #{DEST_TABLE}
      WHERE project_id = OLD.project_id AND user_id = OLD.user_id;
      RETURN OLD;
    END IF;

    RETURN NULL;
  SQL

  def up
    create_trigger_function(FUNCTION_NAME) { FUNCTION_BODY }

    create_trigger(
      SRC_TABLE,
      TRIGGER_NAME,
      FUNCTION_NAME,
      fires: 'AFTER INSERT OR UPDATE OR DELETE')
  end

  def down
    drop_trigger(SRC_TABLE, TRIGGER_NAME)

    drop_function(FUNCTION_NAME)
  end
end
