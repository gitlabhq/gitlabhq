# frozen_string_literal: true

class AddStripeIdentifiersToCreditCardValidation < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.2'

  def up
    with_lock_retries do
      add_column :user_credit_card_validations, :stripe_setup_intent_xid, :text, if_not_exists: true
      add_column :user_credit_card_validations, :stripe_payment_method_xid, :text, if_not_exists: true
      add_column :user_credit_card_validations, :stripe_card_fingerprint, :text, if_not_exists: true
    end

    # Stripe identifiers are currently only around 32 characters, but setting character limit to 255 per the API
    # upgrade guidance for compatability with future Stripe-side changes.
    #
    # More info: https://docs.stripe.com/upgrades
    add_text_limit :user_credit_card_validations, :stripe_setup_intent_xid, 255
    add_text_limit :user_credit_card_validations, :stripe_payment_method_xid, 255
    add_text_limit :user_credit_card_validations, :stripe_card_fingerprint, 255
  end

  def down
    remove_column :user_credit_card_validations, :stripe_setup_intent_xid, if_exists: true
    remove_column :user_credit_card_validations, :stripe_payment_method_xid, if_exists: true
    remove_column :user_credit_card_validations, :stripe_card_fingerprint, if_exists: true
  end
end
