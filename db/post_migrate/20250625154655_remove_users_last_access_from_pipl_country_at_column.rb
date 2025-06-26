# frozen_string_literal: true

class RemoveUsersLastAccessFromPiplCountryAtColumn < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  TABLE_NAME = :users
  COLUMN_NAME = :last_access_from_pipl_country_at

  def up
    remove_column TABLE_NAME, COLUMN_NAME
  end

  def down
    add_column TABLE_NAME, COLUMN_NAME, :datetime_with_timezone, if_not_exists: true
  end
end
