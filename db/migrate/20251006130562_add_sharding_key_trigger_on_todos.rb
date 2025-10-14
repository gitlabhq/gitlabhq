# frozen_string_literal: true

class AddShardingKeyTriggerOnTodos < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  include Gitlab::Database::SchemaHelpers

  TABLE_NAME = 'todos'
  TRIGGER_FUNCTION_NAME = 'todos_sharding_key'
  TRIGGER_NAME = "trigger_#{TRIGGER_FUNCTION_NAME}"

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{TRIGGER_FUNCTION_NAME}() RETURNS TRIGGER AS $$
      BEGIN
        IF num_nonnulls(NEW.organization_id, NEW.group_id, NEW.project_id) != 1 THEN
          IF NEW.project_id IS NOT NULL THEN
            NEW.organization_id := NULL;
            NEW.group_id := NULL;
          ELSIF NEW.group_id IS NOT NULL THEN
            NEW.organization_id := NULL;
            NEW.project_id := NULL;
          ELSE
            SELECT "organization_id", NULL, NULL
            INTO NEW."organization_id", NEW."group_id", NEW."project_id"
            FROM "users"
            WHERE "users"."id" = NEW."user_id";
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
