# frozen_string_literal: true

class AddHasExternalIssueTrackerTrigger < ActiveRecord::Migration[6.0]
  include Gitlab::Database::SchemaHelpers

  DOWNTIME = false
  FUNCTION_NAME = 'set_has_external_issue_tracker'
  TRIGGER_ON_INSERT_NAME = 'trigger_has_external_issue_tracker_on_insert'
  TRIGGER_ON_UPDATE_NAME = 'trigger_has_external_issue_tracker_on_update'
  TRIGGER_ON_DELETE_NAME = 'trigger_has_external_issue_tracker_on_delete'

  def up
    create_trigger_function(FUNCTION_NAME, replace: true) do
      <<~SQL
        UPDATE projects SET has_external_issue_tracker = (
          EXISTS
          (
            SELECT 1
            FROM services
            WHERE project_id = COALESCE(NEW.project_id, OLD.project_id)
              AND active = TRUE
              AND category = 'issue_tracker'
          )
        )
        WHERE projects.id = COALESCE(NEW.project_id, OLD.project_id);
        RETURN NULL;
      SQL
    end

    execute(<<~SQL)
      CREATE TRIGGER #{TRIGGER_ON_INSERT_NAME}
      AFTER INSERT ON services
      FOR EACH ROW
      WHEN (NEW.category = 'issue_tracker' AND NEW.active = TRUE AND NEW.project_id IS NOT NULL)
      EXECUTE FUNCTION #{FUNCTION_NAME}();
    SQL

    execute(<<~SQL)
      CREATE TRIGGER #{TRIGGER_ON_UPDATE_NAME}
      AFTER UPDATE ON services
      FOR EACH ROW
      WHEN (NEW.category = 'issue_tracker' AND OLD.active != NEW.active AND NEW.project_id IS NOT NULL)
      EXECUTE FUNCTION #{FUNCTION_NAME}();
    SQL

    execute(<<~SQL)
      CREATE TRIGGER #{TRIGGER_ON_DELETE_NAME}
      AFTER DELETE ON services
      FOR EACH ROW
      WHEN (OLD.category = 'issue_tracker' AND OLD.active = TRUE AND OLD.project_id IS NOT NULL)
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
