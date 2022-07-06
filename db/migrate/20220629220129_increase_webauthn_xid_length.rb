# frozen_string_literal: true

class IncreaseWebauthnXidLength < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    new_constraint_name = check_constraint_name(:webauthn_registrations, :credential_xid, 'max_length_v3')
    add_text_limit :webauthn_registrations, :credential_xid, 1364, constraint_name: new_constraint_name

    prev_constraint_name = check_constraint_name(:webauthn_registrations, :credential_xid, 'max_length_v2')
    remove_text_limit :webauthn_registrations, :credential_xid, constraint_name: prev_constraint_name
  end

  def down
    # no-op: Danger of failling if there are records with length(credential_xid) > 1364
  end
end
