# frozen_string_literal: true

class CreatePiplUsersTable < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def up
    create_table :pipl_users, id: false do |t|
      t.references :user, primary_key: true, default: nil, index: false, foreign_key: { on_delete: :cascade }

      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :initial_email_sent_at, index: true
      t.datetime_with_timezone :last_access_from_pipl_country_at, null: false
    end
  end

  def down
    drop_table :pipl_users
  end
end
