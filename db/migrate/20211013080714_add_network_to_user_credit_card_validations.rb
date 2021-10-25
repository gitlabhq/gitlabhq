# frozen_string_literal: true

class AddNetworkToUserCreditCardValidations < Gitlab::Database::Migration[1.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  def change
    add_column :user_credit_card_validations, :network, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
