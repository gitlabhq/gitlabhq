# frozen_string_literal: true

class IndexMetaDataOnUserCreditCardValidations < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_user_credit_card_validations_meta_data_full_match'

  def up
    add_concurrent_index :user_credit_card_validations,
      [:holder_name, :expiration_date, :last_digits, :credit_card_validated_at],
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index :user_credit_card_validations,
      [:holder_name, :expiration_date, :last_digits, :credit_card_validated_at],
      name: INDEX_NAME
  end
end
