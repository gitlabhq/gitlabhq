# frozen_string_literal: true

class LimitNetworkOnUserCreditCardValidations < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :user_credit_card_validations, :network, 32
  end

  def down
    remove_text_limit :user_credit_card_validations, :network
  end
end
