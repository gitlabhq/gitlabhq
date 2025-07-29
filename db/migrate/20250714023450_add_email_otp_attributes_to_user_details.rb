# frozen_string_literal: true

class AddEmailOtpAttributesToUserDetails < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      # Add a comment to signal the limit will need to be increased if
      # the hashing algorithm is changed.
      add_column :user_details, :email_otp, :text, if_not_exists: true, comment: 'SHA256 hash (64 hex characters)'
      add_column :user_details, :email_otp_last_sent_to, :text, if_not_exists: true
      add_column :user_details, :email_otp_last_sent_at, :datetime_with_timezone, if_not_exists: true
      add_column :user_details, :email_otp_required_after, :datetime_with_timezone, if_not_exists: true
    end

    add_text_limit :user_details, :email_otp, 64
    add_text_limit :user_details, :email_otp_last_sent_to, 511
  end

  def down
    remove_text_limit :user_details, :email_otp_last_sent_to
    remove_text_limit :user_details, :email_otp

    with_lock_retries do
      remove_column :user_details, :email_otp_required_after
      remove_column :user_details, :email_otp_last_sent_at

      remove_column :user_details, :email_otp_last_sent_to
      remove_column :user_details, :email_otp
    end
  end
end
