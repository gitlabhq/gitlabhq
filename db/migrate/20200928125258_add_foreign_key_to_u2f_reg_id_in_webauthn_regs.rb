# frozen_string_literal: true

class AddForeignKeyToU2fRegIdInWebauthnRegs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_webauthn_registrations_on_u2f_registration_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :webauthn_registrations, :u2f_registration_id, where: 'u2f_registration_id IS NOT NULL', name: INDEX_NAME
    add_concurrent_foreign_key :webauthn_registrations, :u2f_registrations, column: :u2f_registration_id, on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :webauthn_registrations, column: :u2f_registration_id
    remove_concurrent_index_by_name(:webauthn_registrations, INDEX_NAME)
  end
end
