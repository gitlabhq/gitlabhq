# frozen_string_literal: true

class AddIndexOnUserStatusesStatusExpiresAt < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_user_statuses_on_clear_status_at_not_null'

  disable_ddl_transaction!

  def up
    add_concurrent_index(:user_statuses, :clear_status_at, name: INDEX_NAME, where: 'clear_status_at IS NOT NULL')
  end

  def down
    remove_concurrent_index_by_name(:user_statuses, INDEX_NAME)
  end
end
