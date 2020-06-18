# frozen_string_literal: true

class AddIndexToPersonalAccessTokenImpersonation < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_expired_and_not_notified_personal_access_tokens'

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :personal_access_tokens,
      [:id, :expires_at],
      where: "impersonation = FALSE AND revoked = FALSE AND expire_notification_delivered = FALSE",
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(
      :personal_access_tokens,
      name: INDEX_NAME
    )
  end
end
