# frozen_string_literal: true

class RemovePlainTextCreditCardColumns < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  disable_ddl_transaction!

  FULL_MATCH_INDEX_NAME = 'index_user_credit_card_validations_meta_data_full_match_lower'
  FULL_MATCH_FIELDS = 'lower(holder_name), expiration_date, last_digits, credit_card_validated_at'

  PARTIAL_MATCH_INDEX_NAME = 'index_user_credit_card_validations_meta_data_partial_match'
  PARTIAL_MATCH_FIELDS = 'expiration_date, last_digits, network, credit_card_validated_at'

  def up
    with_lock_retries do
      remove_column :user_credit_card_validations, :holder_name, if_exists: true
      remove_column :user_credit_card_validations, :network, if_exists: true
      remove_column :user_credit_card_validations, :expiration_date, if_exists: true
      remove_column :user_credit_card_validations, :last_digits, if_exists: true
    end
  end

  def down
    add_column :user_credit_card_validations, :holder_name, :text, if_not_exists: true
    add_column :user_credit_card_validations, :network, :text, if_not_exists: true
    add_column :user_credit_card_validations, :expiration_date, :date, if_not_exists: true
    add_column :user_credit_card_validations, :last_digits, :integer, limit: 2, if_not_exists: true

    add_text_limit :user_credit_card_validations, :holder_name, 50
    add_text_limit :user_credit_card_validations, :network, 32
    add_check_constraint :user_credit_card_validations, 'last_digits BETWEEN 0 AND 9999',
      'credit_card_last_digits_range'

    add_concurrent_index :user_credit_card_validations, FULL_MATCH_FIELDS, name: FULL_MATCH_INDEX_NAME
    add_concurrent_index :user_credit_card_validations, PARTIAL_MATCH_FIELDS, name: PARTIAL_MATCH_INDEX_NAME
  end
end
