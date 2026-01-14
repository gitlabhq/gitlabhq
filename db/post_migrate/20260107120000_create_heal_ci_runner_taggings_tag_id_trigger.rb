# frozen_string_literal: true

class CreateHealCiRunnerTaggingsTagIdTrigger < Gitlab::Database::Migration[2.3]
  include ::Gitlab::Database::SchemaHelpers

  milestone '18.9'

  disable_ddl_transaction!

  TABLE_NAME = :ci_runner_taggings
  FUNCTION_NAME = 'heal_ci_runner_taggings_tag_id'
  TRIGGER_NAME = "#{TABLE_NAME}_heal_tag_id_trigger"
  FUNCTION_BODY = <<~SQL
    IF NEW.tag_id IS NULL AND NEW.tag_name IS NOT NULL THEN
      INSERT INTO tags (name)
      VALUES (NEW.tag_name)
      ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
      RETURNING id INTO NEW.tag_id;
    END IF;

    RETURN NEW;
  SQL

  def up
    create_trigger_function(FUNCTION_NAME) { FUNCTION_BODY }
    create_trigger(
      TABLE_NAME,
      TRIGGER_NAME,
      FUNCTION_NAME,
      fires: 'BEFORE INSERT')

    # Ensure that the trigger is called on a new cell
    execute <<~SQL
      ALTER TABLE #{TABLE_NAME} ENABLE ALWAYS TRIGGER #{TRIGGER_NAME};
    SQL
  end

  def down
    drop_trigger(TABLE_NAME, TRIGGER_NAME)
    drop_function(FUNCTION_NAME)
  end
end
