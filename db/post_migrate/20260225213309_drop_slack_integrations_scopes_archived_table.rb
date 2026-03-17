# frozen_string_literal: true

class DropSlackIntegrationsScopesArchivedTable < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def up
    drop_table :slack_integrations_scopes_archived
  end

  def down
    execute <<~SQL
      CREATE TABLE slack_integrations_scopes_archived (
        id bigint NOT NULL,
        slack_api_scope_id bigint NOT NULL,
        slack_integration_id bigint NOT NULL,
        project_id bigint,
        group_id bigint,
        organization_id bigint,
        archived_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
      );

      COMMENT ON TABLE slack_integrations_scopes_archived IS 'Temporary table for storing duplicate slack_integrations_scopes records during sharding key backfill. Stores duplicate/conflicting records with archival timestamp. TODO: Drop after BBM completion and verification.';

      ALTER TABLE ONLY slack_integrations_scopes_archived
        ADD CONSTRAINT slack_integrations_scopes_archived_pkey PRIMARY KEY (id);
    SQL
  end
end
