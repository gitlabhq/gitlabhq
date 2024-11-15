# frozen_string_literal: true

class AddIndicesForPatExpiryColumns < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.4'

  def up
    add_concurrent_index :personal_access_tokens, # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
      [:expires_at, :id],
      where: 'impersonation = false AND revoked = false AND seven_days_notification_sent_at IS NULL',
      name: 'index_pats_on_expiring_at_seven_days_notification_sent_at'

    add_concurrent_index :personal_access_tokens, # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
      [:expires_at, :id],
      where: 'impersonation = false AND revoked = false AND thirty_days_notification_sent_at IS NULL',
      name: 'index_pats_on_expiring_at_thirty_days_notification_sent_at'

    add_concurrent_index :personal_access_tokens, # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
      [:expires_at, :id],
      where: 'impersonation = false AND revoked = false AND sixty_days_notification_sent_at IS NULL',
      name: 'index_pats_on_expiring_at_sixty_days_notification_sent_at'
  end

  def down
    remove_concurrent_index_by_name :personal_access_tokens,
      name: 'index_pats_on_expiring_at_seven_days_notification_sent_at'
    remove_concurrent_index_by_name :personal_access_tokens,
      name: 'index_pats_on_expiring_at_thirty_days_notification_sent_at'
    remove_concurrent_index_by_name :personal_access_tokens,
      name: 'index_pats_on_expiring_at_sixty_days_notification_sent_at'
  end
end
