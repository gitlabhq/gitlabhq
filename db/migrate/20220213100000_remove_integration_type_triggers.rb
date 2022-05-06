# frozen_string_literal: true

class RemoveIntegrationTypeTriggers < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::SchemaHelpers

  FUNCTION_NAME = 'integrations_set_type_new'
  TRIGGER_ON_INSERT_NAME = 'trigger_type_new_on_insert'

  def up
    drop_trigger(:integrations, TRIGGER_ON_INSERT_NAME)
    drop_function(FUNCTION_NAME)
  end

  def down
    create_trigger_function(FUNCTION_NAME, replace: true) do
      <<~SQL.squish
        UPDATE integrations
           SET type_new = COALESCE(NEW.type_new, regexp_replace(NEW.type, '\\A(.+)Service\\Z', 'Integrations::\\1'))
             , type     = COALESCE(NEW.type, regexp_replace(NEW.type_new, '\\AIntegrations::(.+)\\Z', '\\1Service'))
        WHERE integrations.id = NEW.id;
        RETURN NULL;
      SQL
    end

    execute(<<~SQL)
      CREATE TRIGGER #{TRIGGER_ON_INSERT_NAME}
      AFTER INSERT ON integrations
      FOR EACH ROW
      EXECUTE FUNCTION #{FUNCTION_NAME}();
    SQL
  end
end
