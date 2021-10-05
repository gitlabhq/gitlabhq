# frozen_string_literal: true

class LimitHolderNameOnUserCreditCardValidations < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :user_credit_card_validations, :holder_name, 26 # ISO IEC 7813

    add_check_constraint(:user_credit_card_validations, 'last_digits BETWEEN 0 AND 9999', constraint_name)
  end

  def down
    remove_text_limit :user_credit_card_validations, :holder_name

    remove_check_constraint(:user_credit_card_validations, constraint_name)
  end

  private

  def constraint_name
    check_constraint_name(:user_credit_card_validations, :last_digits, 'range')
  end
end
