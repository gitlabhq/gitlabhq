# frozen_string_literal: true

class AddRedirectRoutesNamespaceIdTrigger < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::SchemaHelpers

  milestone '17.10'

  TRIGGER_FUNCTION_NAME = :sync_redirect_routes_namespace_id
  TRIGGER_NAME = :trigger_sync_redirect_routes_namespace_id

  def up
    create_trigger_function(TRIGGER_FUNCTION_NAME) do
      <<~SQL
        IF NEW."source_type" = 'Namespace' THEN
          NEW."namespace_id" = NEW."source_id";
        ELSIF NEW."source_type" = 'Project' THEN
          NEW."namespace_id" = (SELECT project_namespace_id FROM projects WHERE id = NEW.source_id);
        END IF;

        RETURN NEW;
      SQL
    end

    create_trigger(:redirect_routes, TRIGGER_NAME, TRIGGER_FUNCTION_NAME, fires: 'BEFORE INSERT OR UPDATE') do
      'WHEN (NEW.namespace_id IS NULL)'
    end
  end

  def down
    drop_trigger(:redirect_routes, TRIGGER_NAME)
    drop_function(TRIGGER_FUNCTION_NAME)
  end
end
