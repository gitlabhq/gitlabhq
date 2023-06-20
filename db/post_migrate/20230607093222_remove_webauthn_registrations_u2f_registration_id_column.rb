# frozen_string_literal: true

class RemoveWebauthnRegistrationsU2fRegistrationIdColumn < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_webauthn_registrations_on_u2f_registration_id'

  def up
    remove_column :webauthn_registrations, :u2f_registration_id
  end

  def down
    add_column :webauthn_registrations, :u2f_registration_id, :integer

    add_concurrent_index(
      :webauthn_registrations,
      :u2f_registration_id,
      name: INDEX_NAME,
      where: 'u2f_registration_id IS NOT NULL')
  end
end
