# frozen_string_literal: true

class AddHashesToCreditCardValidations < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :user_credit_card_validations, :last_digits_hash, :text, if_not_exists: true
      add_column :user_credit_card_validations, :holder_name_hash, :text, if_not_exists: true
      add_column :user_credit_card_validations, :expiration_date_hash, :text, if_not_exists: true
      add_column :user_credit_card_validations, :network_hash, :text, if_not_exists: true
    end

    add_text_limit :user_credit_card_validations, :last_digits_hash, 44
    add_text_limit :user_credit_card_validations, :holder_name_hash, 44
    add_text_limit :user_credit_card_validations, :expiration_date_hash, 44
    add_text_limit :user_credit_card_validations, :network_hash, 44
  end

  def down
    with_lock_retries do
      remove_column :user_credit_card_validations, :last_digits_hash, if_exists: true
      remove_column :user_credit_card_validations, :holder_name_hash, if_exists: true
      remove_column :user_credit_card_validations, :expiration_date_hash, if_exists: true
      remove_column :user_credit_card_validations, :network_hash, if_exists: true
    end
  end
end
