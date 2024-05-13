# frozen_string_literal: true

class IncreaseAtlassianTokenConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  CONSTRAINT_NAME = 'atlassian_identities_token_length_constraint'

  disable_ddl_transaction!

  def up
    remove_check_constraint(:atlassian_identities, CONSTRAINT_NAME)
    add_check_constraint :atlassian_identities, 'octet_length(encrypted_token) <= 5120', CONSTRAINT_NAME
  end

  def down
    remove_check_constraint(:atlassian_identities, CONSTRAINT_NAME)
    add_check_constraint :atlassian_identities, 'octet_length(encrypted_token) <= 2048', CONSTRAINT_NAME
  end
end
