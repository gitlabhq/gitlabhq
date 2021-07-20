# frozen_string_literal: true

class RenameServicesToIntegrations < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers
  include Gitlab::Database::SchemaHelpers

  # Function and trigger names match those migrated in:
  # - https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49916
  # - https://gitlab.com/gitlab-org/gitlab/-/merge_requests/51852

  WIKI_FUNCTION_NAME = 'set_has_external_wiki'
  TRACKER_FUNCTION_NAME = 'set_has_external_issue_tracker'

  WIKI_TRIGGER_ON_INSERT_NAME = 'trigger_has_external_wiki_on_insert'
  WIKI_TRIGGER_ON_UPDATE_NAME = 'trigger_has_external_wiki_on_update'
  WIKI_TRIGGER_ON_DELETE_NAME = 'trigger_has_external_wiki_on_delete'

  TRACKER_TRIGGER_ON_INSERT_NAME = 'trigger_has_external_issue_tracker_on_insert'
  TRACKER_TRIGGER_ON_UPDATE_NAME = 'trigger_has_external_issue_tracker_on_update'
  TRACKER_TRIGGER_ON_DELETE_NAME = 'trigger_has_external_issue_tracker_on_delete'

  ALL_TRIGGERS = [
    WIKI_TRIGGER_ON_INSERT_NAME,
    WIKI_TRIGGER_ON_UPDATE_NAME,
    WIKI_TRIGGER_ON_DELETE_NAME,
    TRACKER_TRIGGER_ON_INSERT_NAME,
    TRACKER_TRIGGER_ON_UPDATE_NAME,
    TRACKER_TRIGGER_ON_DELETE_NAME
  ].freeze

  def up
    execute('LOCK services IN ACCESS EXCLUSIVE MODE')

    drop_all_triggers(:services)

    rename_table_safely(:services, :integrations)

    recreate_all_triggers(:integrations)
  end

  def down
    execute('LOCK integrations IN ACCESS EXCLUSIVE MODE')

    drop_all_triggers(:integrations)

    undo_rename_table_safely(:services, :integrations)

    recreate_all_triggers(:services)
  end

  private

  def drop_all_triggers(table_name)
    ALL_TRIGGERS.each do |trigger_name|
      drop_trigger(table_name, trigger_name)
    end
  end

  def recreate_all_triggers(table_name)
    wiki_create_insert_trigger(table_name)
    wiki_create_update_trigger(table_name)
    wiki_create_delete_trigger(table_name)

    tracker_replace_trigger_function(table_name)

    tracker_create_insert_trigger(table_name)
    tracker_create_update_trigger(table_name)
    tracker_create_delete_trigger(table_name)
  end

  def wiki_create_insert_trigger(table_name)
    execute(<<~SQL)
      CREATE TRIGGER #{WIKI_TRIGGER_ON_INSERT_NAME}
      AFTER INSERT ON #{table_name}
      FOR EACH ROW
      WHEN (NEW.active = TRUE AND NEW.type = 'ExternalWikiService' AND NEW.project_id IS NOT NULL)
      EXECUTE FUNCTION #{WIKI_FUNCTION_NAME}();
    SQL
  end

  def wiki_create_update_trigger(table_name)
    execute(<<~SQL)
      CREATE TRIGGER #{WIKI_TRIGGER_ON_UPDATE_NAME}
      AFTER UPDATE ON #{table_name}
      FOR EACH ROW
      WHEN (NEW.type = 'ExternalWikiService' AND OLD.active != NEW.active AND NEW.project_id IS NOT NULL)
      EXECUTE FUNCTION #{WIKI_FUNCTION_NAME}();
    SQL
  end

  def wiki_create_delete_trigger(table_name)
    execute(<<~SQL)
      CREATE TRIGGER #{WIKI_TRIGGER_ON_DELETE_NAME}
      AFTER DELETE ON #{table_name}
      FOR EACH ROW
      WHEN (OLD.type = 'ExternalWikiService' AND OLD.project_id IS NOT NULL)
      EXECUTE FUNCTION #{WIKI_FUNCTION_NAME}();
    SQL
  end

  # Using `replace: true` to rewrite the existing function
  def tracker_replace_trigger_function(table_name)
    create_trigger_function(TRACKER_FUNCTION_NAME, replace: true) do
      <<~SQL
        UPDATE projects SET has_external_issue_tracker = (
          EXISTS
          (
            SELECT 1
            FROM #{table_name}
            WHERE project_id = COALESCE(NEW.project_id, OLD.project_id)
              AND active = TRUE
              AND category = 'issue_tracker'
          )
        )
        WHERE projects.id = COALESCE(NEW.project_id, OLD.project_id);
        RETURN NULL;
      SQL
    end
  end

  def tracker_create_insert_trigger(table_name)
    execute(<<~SQL)
      CREATE TRIGGER #{TRACKER_TRIGGER_ON_INSERT_NAME}
      AFTER INSERT ON #{table_name}
      FOR EACH ROW
      WHEN (NEW.category = 'issue_tracker' AND NEW.active = TRUE AND NEW.project_id IS NOT NULL)
      EXECUTE FUNCTION #{TRACKER_FUNCTION_NAME}();
    SQL
  end

  def tracker_create_update_trigger(table_name)
    execute(<<~SQL)
      CREATE TRIGGER #{TRACKER_TRIGGER_ON_UPDATE_NAME}
      AFTER UPDATE ON #{table_name}
      FOR EACH ROW
      WHEN (NEW.category = 'issue_tracker' AND OLD.active != NEW.active AND NEW.project_id IS NOT NULL)
      EXECUTE FUNCTION #{TRACKER_FUNCTION_NAME}();
    SQL
  end

  def tracker_create_delete_trigger(table_name)
    execute(<<~SQL)
      CREATE TRIGGER #{TRACKER_TRIGGER_ON_DELETE_NAME}
      AFTER DELETE ON #{table_name}
      FOR EACH ROW
      WHEN (OLD.category = 'issue_tracker' AND OLD.active = TRUE AND OLD.project_id IS NOT NULL)
      EXECUTE FUNCTION #{TRACKER_FUNCTION_NAME}();
    SQL
  end
end
