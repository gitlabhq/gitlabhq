# frozen_string_literal: true

class RemoveUserDetailsOrganizationColumn < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  TABLE_NAME = :user_details
  COLUMN_NAME = :organization

  def up
    remove_column TABLE_NAME, COLUMN_NAME, if_exists: true
  end

  def down
    add_column TABLE_NAME, COLUMN_NAME, :text, default: '', null: false, if_not_exists: true

    add_text_limit TABLE_NAME, COLUMN_NAME, 500
  end
end
