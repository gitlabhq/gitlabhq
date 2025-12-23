# frozen_string_literal: true

class CreateSlackIntegrationsScopesArchived < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  def up
    execute <<~SQL
      CREATE TABLE slack_integrations_scopes_archived (
        LIKE slack_integrations_scopes
      );
    SQL

    execute <<~SQL
      ALTER TABLE slack_integrations_scopes_archived ADD PRIMARY KEY (id);
    SQL

    add_column :slack_integrations_scopes_archived,
      :archived_at,
      :timestamptz,
      null: false,
      default: -> { 'CURRENT_TIMESTAMP' }

    execute <<~SQL
      COMMENT ON TABLE slack_integrations_scopes_archived IS
      'Temporary table for storing duplicate slack_integrations_scopes records during sharding key backfill. Stores duplicate/conflicting records with archival timestamp. TODO: Drop after BBM completion and verification.';
    SQL
  end

  def down
    drop_table :slack_integrations_scopes_archived, if_exists: true
  end
end
