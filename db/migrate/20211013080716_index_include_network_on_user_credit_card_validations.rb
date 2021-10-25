# frozen_string_literal: true

class IndexIncludeNetworkOnUserCreditCardValidations < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_user_credit_card_validations_meta_data_partial_match'

  def up
    add_concurrent_index :user_credit_card_validations,
      [:expiration_date, :last_digits, :network, :credit_card_validated_at],
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :user_credit_card_validations, INDEX_NAME
  end
end
