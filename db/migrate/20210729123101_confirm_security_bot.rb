# frozen_string_literal: true

class ConfirmSecurityBot < ActiveRecord::Migration[6.0]
  class User < ActiveRecord::Base
    self.table_name = 'users'
    SECURITY_BOT_TYPE = 8
  end

  def up
    User.where(user_type: User::SECURITY_BOT_TYPE, confirmed_at: nil)
      .update_all(confirmed_at: Time.current)
  end

  # no-op
  # Security Bot should be always confirmed
  def down
  end
end
