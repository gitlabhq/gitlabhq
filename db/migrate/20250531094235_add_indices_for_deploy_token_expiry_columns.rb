# frozen_string_literal: true

class AddIndicesForDeployTokenExpiryColumns < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.2'

  def up
    add_concurrent_index :deploy_tokens,
      [:expires_at, :id],
      where: 'revoked = false AND seven_days_notification_sent_at IS NULL',
      name: 'index_dts_on_expiring_at_seven_days_notification_sent_at'

    add_concurrent_index :deploy_tokens,
      [:expires_at, :id],
      where: 'revoked = false AND thirty_days_notification_sent_at IS NULL',
      name: 'index_dts_on_expiring_at_thirty_days_notification_sent_at'

    add_concurrent_index :deploy_tokens,
      [:expires_at, :id],
      where: 'revoked = false AND sixty_days_notification_sent_at IS NULL',
      name: 'index_dts_on_expiring_at_sixty_days_notification_sent_at'
  end

  def down
    remove_concurrent_index_by_name :deploy_tokens,
      name: 'index_dts_on_expiring_at_seven_days_notification_sent_at'
    remove_concurrent_index_by_name :deploy_tokens,
      name: 'index_dts_on_expiring_at_thirty_days_notification_sent_at'
    remove_concurrent_index_by_name :deploy_tokens,
      name: 'index_dts_on_expiring_at_sixty_days_notification_sent_at'
  end
end
