# frozen_string_literal: true

class AddShardingKeyTriggerOnClusterProvidersGcp < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  include Gitlab::Database::SchemaHelpers

  TABLE_NAME = 'cluster_providers_gcp'
  TRIGGER_FUNCTION_NAME = 'cluster_providers_gcp_sharding_key'
  TRIGGER_NAME = "trigger_#{TRIGGER_FUNCTION_NAME}"

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{TRIGGER_FUNCTION_NAME}() RETURNS TRIGGER AS $$
      BEGIN
        IF num_nonnulls(NEW.organization_id, NEW.group_id, NEW.project_id) != 1 THEN
          SELECT "organization_id", "group_id", "project_id"
          INTO NEW."organization_id", NEW."group_id", NEW."project_id"
          FROM "clusters"
          WHERE "clusters"."id" = NEW."cluster_id";
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
