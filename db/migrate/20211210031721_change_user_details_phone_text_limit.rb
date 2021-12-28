# frozen_string_literal: true

class ChangeUserDetailsPhoneTextLimit < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    remove_text_limit :user_details, :phone
    add_text_limit :user_details, :phone, 50
  end

  def down
    remove_text_limit :user_details, :phone
    add_text_limit :user_details, :phone, 32
  end
end
