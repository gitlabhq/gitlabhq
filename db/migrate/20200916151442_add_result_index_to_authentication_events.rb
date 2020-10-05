# frozen_string_literal: true

class AddResultIndexToAuthenticationEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_authentication_events_on_provider_user_id_created_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :authentication_events, [:provider, :user_id, :created_at], where: 'result = 1', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :authentication_events, INDEX_NAME
  end
end
