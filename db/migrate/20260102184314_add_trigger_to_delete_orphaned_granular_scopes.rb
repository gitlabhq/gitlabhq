# frozen_string_literal: true

class AddTriggerToDeleteOrphanedGranularScopes < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  milestone '18.8'

  TABLE_NAME = :personal_access_token_granular_scopes
  TRIGGER_NAME = 'trigger_delete_orphaned_granular_scopes'
  FUNCTION_NAME = 'delete_orphaned_granular_scopes'

  def up
    # Create a function that deletes orphaned granular_scopes records
    # when a personal_access_token_granular_scopes record is deleted
    create_trigger_function(FUNCTION_NAME) do
      <<~SQL
        DELETE FROM granular_scopes
        WHERE id = OLD.granular_scope_id
        AND NOT EXISTS (
          SELECT 1
          FROM personal_access_token_granular_scopes
          WHERE granular_scope_id = OLD.granular_scope_id
        );
        RETURN OLD;
      SQL
    end

    create_trigger(TABLE_NAME, TRIGGER_NAME, FUNCTION_NAME, fires: 'AFTER DELETE')
  end

  def down
    drop_trigger(TABLE_NAME, TRIGGER_NAME)
    drop_function(FUNCTION_NAME)
  end
end
