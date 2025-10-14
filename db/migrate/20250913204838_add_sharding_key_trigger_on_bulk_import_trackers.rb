# frozen_string_literal: true

class AddShardingKeyTriggerOnBulkImportTrackers < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  include Gitlab::Database::SchemaHelpers

  TABLE_NAME = 'bulk_import_trackers'
  TRIGGER_FUNCTION_NAME = 'bulk_import_trackers_sharding_key'
  TRIGGER_NAME = "trigger_#{TRIGGER_FUNCTION_NAME}"

  def up
    # NOTE: creating a new trigger reflecting https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188587#note_2651635058
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{TRIGGER_FUNCTION_NAME}() RETURNS TRIGGER AS $$
      BEGIN
        IF num_nonnulls(NEW.namespace_id, NEW.organization_id, NEW.project_id) != 1 THEN
          SELECT "organization_id", "namespace_id", "project_id"
          INTO NEW."organization_id", NEW."namespace_id", NEW."project_id"
          FROM "bulk_import_entities"
          WHERE "bulk_import_entities"."id" = NEW."bulk_import_entity_id";
        END IF;

        RETURN NEW;
      END
      $$ LANGUAGE PLPGSQL
    SQL

    create_trigger(
      TABLE_NAME,
      TRIGGER_NAME,
      TRIGGER_FUNCTION_NAME,
      fires: 'BEFORE INSERT OR UPDATE'
    )
  end

  def down
    drop_trigger(TABLE_NAME, TRIGGER_NAME)
    drop_function(TRIGGER_FUNCTION_NAME)
  end
end
