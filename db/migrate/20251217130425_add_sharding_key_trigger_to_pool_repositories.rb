# frozen_string_literal: true

class AddShardingKeyTriggerToPoolRepositories < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  milestone '18.8'

  TABLE_NAME = 'pool_repositories'
  TRIGGER_FUNCTION_NAME = 'pool_repositories_sharding_key'
  TRIGGER_NAME = "trigger_#{TRIGGER_FUNCTION_NAME}"

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{TRIGGER_FUNCTION_NAME}() RETURNS TRIGGER AS $$
      BEGIN
        IF NEW.organization_id IS NOT NULL THEN
          RETURN NEW;
        END IF;

        IF NEW.source_project_id IS NOT NULL THEN
          SELECT p.organization_id
          INTO NEW.organization_id
          FROM projects p
          WHERE p.id = NEW.source_project_id;
        END IF;

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
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
