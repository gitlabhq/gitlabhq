# frozen_string_literal: true

class DeleteProjectNamespaceTrigger < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::SchemaHelpers

  TRIGGER_NAME = "trigger_delete_project_namespace_on_project_delete"
  FUNCTION_NAME = 'delete_associated_project_namespace'

  def up
    create_trigger_function(FUNCTION_NAME, replace: true) do
      <<~SQL
        DELETE FROM namespaces
        WHERE namespaces.id = OLD.project_namespace_id AND
        namespaces.type = 'Project';
        RETURN NULL;
      SQL
    end

    execute(<<~SQL.squish)
      CREATE TRIGGER #{TRIGGER_NAME}
        AFTER DELETE ON projects FOR EACH ROW
        WHEN (OLD.project_namespace_id IS NOT NULL)
        EXECUTE FUNCTION #{FUNCTION_NAME}();
    SQL
  end

  def down
    drop_trigger(:projects, TRIGGER_NAME)
    drop_function(FUNCTION_NAME)
  end
end
