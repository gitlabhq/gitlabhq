# frozen_string_literal: true

class AddProjectFallbackToWikiUserMentionTrigger < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  milestone '19.3'

  TRIGGER_NAME = 'trigger_2cb7e7147818'

  def up
    create_trigger_function(TRIGGER_NAME) do
      <<~SQL
        IF NEW."namespace_id" IS NULL THEN
          SELECT COALESCE("notes"."namespace_id", "projects"."project_namespace_id")
          INTO NEW."namespace_id"
          FROM "notes"
          LEFT JOIN "projects" ON "projects"."id" = "notes"."project_id"
          WHERE "notes"."id" = NEW."note_id";
        END IF;

        RETURN NEW;
      SQL
    end
  end

  def down
    create_trigger_function(TRIGGER_NAME) do
      <<~SQL
        IF NEW."namespace_id" IS NULL THEN
          SELECT "namespace_id"
          INTO NEW."namespace_id"
          FROM "notes"
          WHERE "notes"."id" = NEW."note_id";
        END IF;

        RETURN NEW;
      SQL
    end
  end
end
