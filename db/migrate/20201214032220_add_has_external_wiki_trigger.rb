# frozen_string_literal: true

class AddHasExternalWikiTrigger < ActiveRecord::Migration[6.0]
  include Gitlab::Database::SchemaHelpers

  DOWNTIME = false
  FUNCTION_NAME = 'set_has_external_wiki'
  TRIGGER_ON_INSERT_NAME = 'trigger_has_external_wiki_on_insert'
  TRIGGER_ON_UPDATE_NAME = 'trigger_has_external_wiki_on_update'
  TRIGGER_ON_DELETE_NAME = 'trigger_has_external_wiki_on_delete'

  def up
    create_trigger_function(FUNCTION_NAME, replace: true) do
      <<~SQL
        UPDATE projects SET has_external_wiki = COALESCE(NEW.active, FALSE)
        WHERE projects.id = COALESCE(NEW.project_id, OLD.project_id);
        RETURN NULL;
      SQL
    end

    execute(<<~SQL)
      CREATE TRIGGER #{TRIGGER_ON_INSERT_NAME}
      AFTER INSERT ON services
      FOR EACH ROW
      WHEN (NEW.active = TRUE AND NEW.type = 'ExternalWikiService' AND NEW.project_id IS NOT NULL)
      EXECUTE FUNCTION #{FUNCTION_NAME}();
    SQL

    execute(<<~SQL)
      CREATE TRIGGER #{TRIGGER_ON_UPDATE_NAME}
      AFTER UPDATE ON services
      FOR EACH ROW
      WHEN (NEW.type = 'ExternalWikiService' AND OLD.active != NEW.active AND NEW.project_id IS NOT NULL)
      EXECUTE FUNCTION #{FUNCTION_NAME}();
    SQL

    execute(<<~SQL)
      CREATE TRIGGER #{TRIGGER_ON_DELETE_NAME}
      AFTER DELETE ON services
      FOR EACH ROW
      WHEN (OLD.type = 'ExternalWikiService' AND OLD.project_id IS NOT NULL)
      EXECUTE FUNCTION #{FUNCTION_NAME}();
    SQL
  end

  def down
    drop_trigger(:services, TRIGGER_ON_INSERT_NAME)
    drop_trigger(:services, TRIGGER_ON_UPDATE_NAME)
    drop_trigger(:services, TRIGGER_ON_DELETE_NAME)
    drop_function(FUNCTION_NAME)
  end
end
