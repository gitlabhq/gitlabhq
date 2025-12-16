# frozen_string_literal: true

class AddUniqueIndexToRawUsageDataOnOrganizationIdAndRecordedAt < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.7'

  INDEX_NAME = 'index_raw_usage_data_on_organization_id_recorded_at'

  def up
    add_concurrent_index(
      :raw_usage_data,
      [:organization_id, :recorded_at],
      name: INDEX_NAME,
      unique: true
    )
  end

  def down
    remove_concurrent_index(
      :raw_usage_data,
      [:organization_id, :recorded_at],
      name: INDEX_NAME
    )
  end
end
