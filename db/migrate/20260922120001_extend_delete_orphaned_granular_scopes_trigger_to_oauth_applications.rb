# frozen_string_literal: true

class ExtendDeleteOrphanedGranularScopesTriggerToOauthApplications < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::SchemaHelpers

  milestone '19.5'

  TABLE_NAME = :oauth_application_granular_scopes
  TRIGGER_NAME = 'trigger_delete_orphaned_granular_scopes_for_oauth_apps'
  FUNCTION_NAME = 'delete_orphaned_granular_scopes'

  def up
    create_trigger_function(FUNCTION_NAME) do
      <<~SQL
        DELETE FROM granular_scopes
        WHERE id = OLD.granular_scope_id
        AND NOT EXISTS (
          SELECT 1
          FROM personal_access_token_granular_scopes
          WHERE granular_scope_id = OLD.granular_scope_id
        )
        AND NOT EXISTS (
          SELECT 1
          FROM oauth_consent_grant_granular_scopes
          WHERE granular_scope_id = OLD.granular_scope_id
        )
        AND NOT EXISTS (
          SELECT 1
          FROM oauth_application_granular_scopes
          WHERE granular_scope_id = OLD.granular_scope_id
        );
        RETURN OLD;
      SQL
    end

    create_trigger(TABLE_NAME, TRIGGER_NAME, FUNCTION_NAME, fires: 'AFTER DELETE')
  end

  def down
    drop_trigger(TABLE_NAME, TRIGGER_NAME)

    create_trigger_function(FUNCTION_NAME) do
      <<~SQL
        DELETE FROM granular_scopes
        WHERE id = OLD.granular_scope_id
        AND NOT EXISTS (
          SELECT 1
          FROM personal_access_token_granular_scopes
          WHERE granular_scope_id = OLD.granular_scope_id
        )
        AND NOT EXISTS (
          SELECT 1
          FROM oauth_consent_grant_granular_scopes
          WHERE granular_scope_id = OLD.granular_scope_id
        );
        RETURN OLD;
      SQL
    end
  end
end
