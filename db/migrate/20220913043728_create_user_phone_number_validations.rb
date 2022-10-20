# frozen_string_literal: true

class CreateUserPhoneNumberValidations < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    create_table :user_phone_number_validations, id: false do |t|
      t.references :user, primary_key: true, default: nil, type: :bigint, index: false,
                          foreign_key: { on_delete: :cascade }

      t.datetime_with_timezone :validated_at
      t.timestamps_with_timezone null: false

      t.integer :international_dial_code, null: false, limit: 1
      t.integer :verification_attempts, null: false, default: 0, limit: 1
      t.integer :risk_score, null: false, default: 0, limit: 1

      t.text :country, null: false, limit: 3
      t.text :phone_number, null: false, limit: 12
      t.text :telesign_reference_xid, limit: 255

      t.index [:international_dial_code, :phone_number], name: :index_user_phone_validations_on_dial_code_phone_number
    end
  end

  def down
    drop_table :user_phone_number_validations
  end
end
