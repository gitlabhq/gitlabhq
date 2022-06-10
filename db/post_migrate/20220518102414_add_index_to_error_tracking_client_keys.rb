# frozen_string_literal: true

class AddIndexToErrorTrackingClientKeys < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_error_tracking_client_for_enabled_check'

  def up
    add_concurrent_index(
      :error_tracking_client_keys,
      [:project_id, :public_key],
      where: 'active = true',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(:error_tracking_client_keys, INDEX_NAME)
  end
end
