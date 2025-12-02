# frozen_string_literal: true

class AddOrganisationToRawUsageDataIndex < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.7'

  INDEX_NAME = 'index_raw_usage_data_on_organization_id'

  def up
    remove_concurrent_index :raw_usage_data, :organization_id, name: INDEX_NAME
  end

  def down
    add_concurrent_index :raw_usage_data, :organization_id, name: INDEX_NAME
  end
end
