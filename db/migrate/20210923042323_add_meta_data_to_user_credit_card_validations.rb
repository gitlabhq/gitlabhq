# frozen_string_literal: true

class AddMetaDataToUserCreditCardValidations < Gitlab::Database::Migration[1.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  def change
    change_table :user_credit_card_validations do |t|
      t.date :expiration_date
      t.integer :last_digits, limit: 2 # last 4 digits
      t.text :holder_name
    end
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
