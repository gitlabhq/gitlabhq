# frozen_string_literal: true

class AddOtpSecretToUser < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  def up
    with_lock_retries do
      add_column :users, :otp_secret, :text, if_not_exists: true # rubocop:disable Migration/PreventAddingColumns -- this column is used in devise-two-factor v5
    end

    add_text_limit :users, :otp_secret, 255
  end

  def down
    with_lock_retries do
      remove_column :users, :otp_secret, if_exists: true
    end
  end
end
