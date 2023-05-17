# frozen_string_literal: true

class DropIndexFromWebauthnRegistrationsOnU2fRegistrationId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :webauthn_registrations, column: :u2f_registration_id
    end
  end

  def down
    add_concurrent_foreign_key(
      :webauthn_registrations, :u2f_registrations, column: :u2f_registration_id, on_delete: :cascade)
  end
end
