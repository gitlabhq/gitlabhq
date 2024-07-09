# frozen_string_literal: true

class CreateCountryAccessLogs < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    create_table :country_access_logs do |t|
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :access_count_reset_at
      t.datetime_with_timezone :first_access_at
      t.datetime_with_timezone :last_access_at
      t.bigint :user_id, null: false
      t.integer :access_count, null: false, default: 0
      t.integer :country_code, null: false, limit: 2
      t.index [:user_id, :country_code],
        name: :index_country_access_logs_on_user_id_and_country_code,
        unique: true
    end
  end
end
