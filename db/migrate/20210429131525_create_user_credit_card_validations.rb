# frozen_string_literal: true

class CreateUserCreditCardValidations < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    with_lock_retries do
      create_table :user_credit_card_validations, id: false do |t|
        t.references :user, foreign_key: { on_delete: :cascade }, index: false, primary_key: true, default: nil
        t.datetime_with_timezone :credit_card_validated_at, null: false
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :user_credit_card_validations
    end
  end
end
