# frozen_string_literal: true

class AddLastAccessFromPiplCountryAtToUsers < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  enable_lock_retries!

  # This column prevents additional queries (e.g. 'SELECT ... FROM
  # country_access_logs ...') when checking if the user's access from a specific
  # country should be tracked (insert/update to country_access_logs table).
  # rubocop:disable Migration/PreventAddingColumns -- see previous lines
  def change
    add_column :users, :last_access_from_pipl_country_at, :datetime_with_timezone, if_not_exists: true
  end
  # rubocop:enable Migration/PreventAddingColumns
end
