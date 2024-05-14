# frozen_string_literal: true

class AddOrganisationToRawUsageData < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.10'

  INDEX_NAME = 'index_raw_usage_data_on_organization_id'

  def up
    add_column :raw_usage_data, :organization_id, :bigint, null: false,
      default: Organizations::Organization::DEFAULT_ORGANIZATION_ID

    add_concurrent_foreign_key :raw_usage_data, :organizations, column: :organization_id, on_delete: :cascade
    add_concurrent_index :raw_usage_data, :organization_id, name: INDEX_NAME
  end

  def down
    with_lock_retries do
      remove_foreign_key :raw_usage_data, column: :organization_id
    end

    remove_concurrent_index_by_name :raw_usage_data, INDEX_NAME

    remove_column :raw_usage_data, :organization_id
  end
end
