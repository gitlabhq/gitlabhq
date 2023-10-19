# frozen_string_literal: true

class AddPartialMatchIndexOfHashesOnCreditCardValidations < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_user_credit_card_validations_on_similar_to_meta_data'
  INDEX_FIELDS = [:expiration_date_hash, :last_digits_hash, :network_hash, :credit_card_validated_at]

  def up
    add_concurrent_index :user_credit_card_validations, INDEX_FIELDS, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :user_credit_card_validations, INDEX_NAME
  end
end
