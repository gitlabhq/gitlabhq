# frozen_string_literal: true

class AddRenderWhitespaceInCodeToUserPreference < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column(:user_preferences, :render_whitespace_in_code, :boolean)
  end

  def down
    remove_column(:user_preferences, :render_whitespace_in_code)
  end
end
