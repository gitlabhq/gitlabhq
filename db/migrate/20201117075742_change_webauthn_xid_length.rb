# frozen_string_literal: true

class ChangeWebauthnXidLength < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :webauthn_registrations, :credential_xid, 340, constraint_name: check_constraint_name(:webauthn_registrations, :credential_xid, 'max_length_v2')
    remove_text_limit :webauthn_registrations, :credential_xid, constraint_name: check_constraint_name(:webauthn_registrations, :credential_xid, 'max_length')
  end

  def down
    # no-op: Danger of failling if there are records with length(credential_xid) > 255
  end
end
