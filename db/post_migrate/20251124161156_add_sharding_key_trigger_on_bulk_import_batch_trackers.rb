# frozen_string_literal: true

class AddShardingKeyTriggerOnBulkImportBatchTrackers < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  include Gitlab::Database::SchemaHelpers

  TABLE_NAME = 'bulk_import_batch_trackers'
  TRIGGER_FUNCTION_NAME = 'bulk_import_batch_trackers_sharding_key'
  TRIGGER_NAME = "trigger_#{TRIGGER_FUNCTION_NAME}"

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{TRIGGER_FUNCTION_NAME}() RETURNS TRIGGER AS $$
      BEGIN
        IF num_nonnulls(NEW.organization_id, NEW.namespace_id, NEW.project_id) != 1 THEN
          SELECT "organization_id", "namespace_id", "project_id"
          INTO NEW."organization_id", NEW."namespace_id", NEW."project_id"
          FROM "bulk_import_trackers"
          WHERE "bulk_import_trackers"."id" = NEW."tracker_id";
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
