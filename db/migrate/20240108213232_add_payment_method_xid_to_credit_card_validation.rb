# frozen_string_literal: true

class AddPaymentMethodXidToCreditCardValidation < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.8'

  def up
    with_lock_retries do
      add_column :user_credit_card_validations, :zuora_payment_method_xid, :text, if_not_exists: true
    end

    add_text_limit :user_credit_card_validations, :zuora_payment_method_xid, 50
  end

  def down
    remove_column :user_credit_card_validations, :zuora_payment_method_xid, if_exists: true
  end
end
