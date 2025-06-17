# frozen_string_literal: true

class DropExpiredAndNotNotifiedPatIndex < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.1'

  INDEX_NAME = 'index_expired_and_not_notified_personal_access_tokens'

  def up
    remove_concurrent_index_by_name(:personal_access_tokens, INDEX_NAME)
  end

  def down
    add_concurrent_index(
      :personal_access_tokens, [:id, :expires_at],
      where: 'impersonation = false AND revoked = false AND expire_notification_delivered = false',
      name: INDEX_NAME
    )
  end
end
