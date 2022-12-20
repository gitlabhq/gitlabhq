# frozen_string_literal: true

class RemoveResultIndexFromAuthenticationEvents < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_authentication_events_on_provider_user_id_created_at'

  def up
    remove_concurrent_index_by_name :authentication_events, INDEX_NAME
  end

  def down
    add_concurrent_index :authentication_events,
      [:provider, :user_id, :created_at],
      where: 'result = 1',
      name: INDEX_NAME
  end
end
