# frozen_string_literal: true

class AddUserPhoneNumberValidationTelesignReferenceXidIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_user_phone_number_validations_on_telesign_reference_xid'

  def up
    add_concurrent_index(:user_phone_number_validations, :telesign_reference_xid, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:user_phone_number_validations, INDEX_NAME)
  end
end
