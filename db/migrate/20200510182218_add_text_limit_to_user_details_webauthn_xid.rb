# frozen_string_literal: true

class AddTextLimitToUserDetailsWebauthnXid < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :user_details, :webauthn_xid, 100
  end

  def down
    remove_text_limit :user_details, :webauthn_xid
  end
end
