# frozen_string_literal: true

class AddShardingKeyTriggerOnSystemNoteMetadata < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  FUNCTION_NAME = 'get_sharding_key_from_notes_table'
  TRIGGER_NAME = 'set_sharding_key_for_system_note_metadata_on_insert'

  milestone '18.5'

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{FUNCTION_NAME}()
      RETURNS TRIGGER AS
      $$
      DECLARE
        note_organization_id BIGINT;
        note_project_id BIGINT;
        note_namespace_id BIGINT;
      BEGIN
        IF NEW."note_id" IS NULL OR num_nonnulls(NEW."namespace_id", NEW."organization_id") = 1 THEN
          RETURN NEW;
        END IF;

        SELECT "organization_id", "project_id", "namespace_id"
        INTO note_organization_id, note_project_id, note_namespace_id
        FROM "notes"
        WHERE "id" = NEW."note_id";

        IF note_organization_id IS NOT NULL THEN
          NEW."organization_id" := note_organization_id;
          NEW."namespace_id" := NULL;
        ELSIF note_project_id IS NOT NULL THEN
          SELECT "project_namespace_id" FROM "projects"
          INTO NEW."namespace_id" WHERE "projects"."id" = note_project_id;
          NEW."organization_id" := NULL;
        ELSE
          NEW."namespace_id" := note_namespace_id;
          NEW."organization_id" := NULL;
        END IF;

        RETURN NEW;
      END
      $$ LANGUAGE PLPGSQL;
    SQL

    create_trigger(:system_note_metadata, TRIGGER_NAME, FUNCTION_NAME, fires: 'BEFORE INSERT')
  end

  def down
    drop_trigger(:system_note_metadata, TRIGGER_NAME)

    drop_function(FUNCTION_NAME)
  end
end
