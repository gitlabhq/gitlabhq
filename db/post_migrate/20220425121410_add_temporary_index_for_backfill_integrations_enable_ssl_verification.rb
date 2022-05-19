# frozen_string_literal: true

class AddTemporaryIndexForBackfillIntegrationsEnableSslVerification < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_index_integrations_on_id_where_type_droneci_or_teamcity'
  INDEX_CONDITION = "type_new IN ('Integrations::DroneCi', 'Integrations::Teamcity') " \
    "AND encrypted_properties IS NOT NULL"

  def up
    # this index is used in 20220209121435_backfill_integrations_enable_ssl_verification
    add_concurrent_index :integrations, :id, where: INDEX_CONDITION, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :integrations, INDEX_NAME
  end
end
