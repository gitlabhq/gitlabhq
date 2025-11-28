# frozen_string_literal: true

class AddIndexToWebauthnRegistrationsOnAuthMode < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.7'

  INDEX_NAME = 'index_webauthn_registrations_where_authn_mode_is_one'

  def up
    add_concurrent_index(
      :webauthn_registrations,
      [:authentication_mode],
      where: 'authentication_mode = 1', name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(:webauthn_registrations, INDEX_NAME)
  end
end
