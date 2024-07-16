# frozen_string_literal: true

class AddIndexForStripeCardFingerprintToCreditCardValidation < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.2'

  INDEX_NAME = 'index_user_credit_card_validations_on_stripe_card_fingerprint'

  def up
    add_concurrent_index :user_credit_card_validations,
      :stripe_card_fingerprint,
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index :user_credit_card_validations, :stripe_card_fingerprint, name: INDEX_NAME
  end
end
