# frozen_string_literal: true

class FillGhostUserType < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute('UPDATE users SET user_type = 5 WHERE ghost IS TRUE AND user_type IS NULL')
  end

  def down
    execute('UPDATE users SET user_type = NULL WHERE ghost IS TRUE AND user_type IS NOT NULL')
  end
end
