# frozen_string_literal: true

class AddHolderNameHashIndexOnCreditCardValidations < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_user_credit_card_validations_on_holder_name_hash'

  def up
    add_concurrent_index :user_credit_card_validations, :holder_name_hash, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :user_credit_card_validations, INDEX_NAME
  end
end
