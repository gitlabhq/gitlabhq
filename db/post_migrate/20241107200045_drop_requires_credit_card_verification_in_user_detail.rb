# frozen_string_literal: true

class DropRequiresCreditCardVerificationInUserDetail < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def up
    remove_column :user_details, :requires_credit_card_verification
  end

  def down
    add_column :user_details, :requires_credit_card_verification, :boolean, null: false, default: false
  end
end
