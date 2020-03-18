# frozen_string_literal: true

class MigrateBotTypeToUserType < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute('UPDATE users SET user_type = bot_type WHERE bot_type IS NOT NULL AND user_type IS NULL')
  end

  def down
    execute('UPDATE users SET user_type = NULL WHERE bot_type IS NOT NULL AND bot_type = user_type')
  end
end
