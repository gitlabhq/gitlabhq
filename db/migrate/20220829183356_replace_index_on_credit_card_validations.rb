# frozen_string_literal: true

class ReplaceIndexOnCreditCardValidations < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_user_credit_card_validations_meta_data_full_match'
  NEW_INDEX_NAME = 'index_user_credit_card_validations_meta_data_full_match_lower'
  OLD_FIELDS = [:holder_name, :expiration_date, :last_digits, :credit_card_validated_at]
  NEW_FIELDS = 'lower(holder_name), expiration_date, last_digits, credit_card_validated_at'

  def up
    add_concurrent_index :user_credit_card_validations, NEW_FIELDS, name: NEW_INDEX_NAME
    remove_concurrent_index :user_credit_card_validations, OLD_FIELDS, name: OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :user_credit_card_validations, OLD_FIELDS, name: OLD_INDEX_NAME
    remove_concurrent_index :user_credit_card_validations, NEW_FIELDS, name: NEW_INDEX_NAME
  end
end
