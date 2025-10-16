# frozen_string_literal: true

class AddShardingKeyTriggerOnCommitUserMentions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  FUNCTION_NAME = 'sync_sharding_key_with_notes_table'
  TRIGGER_NAME = 'set_sharding_key_for_commit_user_mentions_on_insert_and_update'

  milestone '18.6'

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{FUNCTION_NAME}()
      RETURNS TRIGGER AS
      $$
      DECLARE
        note_project_id BIGINT;
        note_namespace_id BIGINT;
      BEGIN
        IF NEW."note_id" IS NULL OR NEW."namespace_id" IS NOT NULL THEN
          RETURN NEW;
        END IF;

        SELECT "project_id", "namespace_id"
        INTO note_project_id, note_namespace_id
        FROM "notes"
        WHERE "id" = NEW."note_id";

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

    create_trigger(:commit_user_mentions, TRIGGER_NAME, FUNCTION_NAME, fires: 'BEFORE INSERT OR UPDATE')
  end

  def down
    drop_trigger(:commit_user_mentions, TRIGGER_NAME)
  end
end
