# frozen_string_literal: true

class AddTextLimitToWebauthnRegistrationsCredentialXid < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :webauthn_registrations, :credential_xid, 255
  end

  def down
    remove_text_limit :webauthn_registrations, :credential_xid
  end
end
