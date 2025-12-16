# frozen_string_literal: true

class AddTextLimitToUserDetailCompany < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  def up
    add_text_limit :user_details, :company, 500, validate: false
  end

  def down
    remove_text_limit :user_details, :company
  end
end
