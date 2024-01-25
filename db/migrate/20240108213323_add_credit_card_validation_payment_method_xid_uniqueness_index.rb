# frozen_string_literal: true

class AddCreditCardValidationPaymentMethodXidUniquenessIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.8'

  INDEX_NAME = 'unique_index_for_credit_card_validation_payment_method_xid'

  def up
    add_concurrent_index :user_credit_card_validations,
      :zuora_payment_method_xid,
      unique: true,
      where: 'zuora_payment_method_xid IS NOT NULL',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index :user_credit_card_validations, :zuora_payment_method_xid, unique: true, name: INDEX_NAME
  end
end
