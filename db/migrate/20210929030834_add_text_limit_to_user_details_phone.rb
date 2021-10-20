# frozen_string_literal: true

class AddTextLimitToUserDetailsPhone < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :user_details, :phone, 32
  end

  def down
    remove_text_limit :user_details, :phone
  end
end
