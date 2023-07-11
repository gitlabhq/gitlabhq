# frozen_string_literal: true

class AddExpiresAtToServiceAccessTokens < Gitlab::Database::Migration[2.1]
  def change
    # Code using this table has not been implemented yet.
    # During we run the migration, the table will be empty.
    # rubocop:disable Rails/NotNullColumn
    add_column :service_access_tokens, :expires_at, :datetime_with_timezone, null: false
    # rubocop:enable Rails/NotNullColumn
  end
end
