# frozen_string_literal: true

class AddShardingKeyTriggerOnBulkImportExports < Gitlab::Database::Migration[2.3]
  milestone '19.2'
  include Gitlab::Database::SchemaHelpers

  TABLE_NAME = 'bulk_import_exports'
  TRIGGER_FUNCTION_NAME = 'bulk_import_exports_sharding_key'
  TRIGGER_NAME = "trigger_#{TRIGGER_FUNCTION_NAME}"

  def up
    # bulk_import_exports is scoped by either project_id or group_id (exactly one).
    # Unlike sibling tables that copy the sharding key from a single parent row,
    # the organization_id here must be derived from the grandparent (projects or
    # namespaces), depending on which of project_id / group_id is present.
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{TRIGGER_FUNCTION_NAME}() RETURNS TRIGGER AS $$
      BEGIN
        IF NEW."organization_id" IS NULL THEN
          IF NEW."project_id" IS NOT NULL THEN
            SELECT "organization_id"
            INTO NEW."organization_id"
            FROM "projects"
            WHERE "projects"."id" = NEW."project_id";
          ELSIF NEW."group_id" IS NOT NULL THEN
            SELECT "organization_id"
            INTO NEW."organization_id"
            FROM "namespaces"
            WHERE "namespaces"."id" = NEW."group_id";
          END IF;
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
