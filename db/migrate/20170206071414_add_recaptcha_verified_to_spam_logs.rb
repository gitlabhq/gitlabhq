class AddRecaptchaVerifiedToSpamLogs < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default(:spam_logs, :recaptcha_verified, :boolean, default: false)
  end

  def down
    remove_column(:spam_logs, :recaptcha_verified)
  end
end
