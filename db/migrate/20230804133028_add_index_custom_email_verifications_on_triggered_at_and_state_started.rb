# frozen_string_literal: true

class AddIndexCustomEmailVerificationsOnTriggeredAtAndStateStarted < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'i_custom_email_verifications_on_triggered_at_and_state_started'

  def up
    add_concurrent_index :service_desk_custom_email_verifications, :triggered_at,
      where: 'state = 0',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :service_desk_custom_email_verifications, INDEX_NAME
  end
end
