# frozen_string_literal: true

class AddSmsSentAtAndSmsSendCountToPhoneNumberValidations < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  enable_lock_retries!

  def up
    add_column :user_phone_number_validations, :sms_sent_at, :datetime_with_timezone, null: true
    add_column :user_phone_number_validations, :sms_send_count, :smallint, default: 0, null: false
  end

  def down
    remove_column :user_phone_number_validations, :sms_sent_at, if_exists: true
    remove_column :user_phone_number_validations, :sms_send_count, if_exists: true
  end
end
