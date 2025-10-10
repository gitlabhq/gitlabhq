# frozen_string_literal: true

class AddShardingKeyTriggerOnNoteDiffFiles < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  FUNCTION_NAME = 'ensure_note_diff_files_sharding_key'
  TRIGGER_NAME = 'trigger_ensure_note_diff_files_sharding_key'

  milestone '18.5'

  def up
    execute(<<~SQL)
      CREATE FUNCTION #{FUNCTION_NAME}()
      RETURNS TRIGGER AS
      $$
      DECLARE
        note_project_id BIGINT;
        note_namespace_id BIGINT;
      BEGIN
        SELECT "project_id", "namespace_id"
        INTO note_project_id, note_namespace_id
        FROM "notes"
        WHERE "id" = NEW."diff_note_id";

        IF note_project_id IS NOT NULL THEN
          SELECT "project_namespace_id" FROM "projects"
          INTO NEW."namespace_id" WHERE "projects"."id" = note_project_id;
        ELSE
          NEW."namespace_id" := note_namespace_id;
        END IF;

        RETURN NEW;
      END
      $$ LANGUAGE PLPGSQL;
    SQL

    create_trigger(:note_diff_files, TRIGGER_NAME, FUNCTION_NAME, fires: 'BEFORE INSERT')
  end

  def down
    drop_trigger(:note_diff_files, TRIGGER_NAME)

    drop_function(FUNCTION_NAME)
  end
end
