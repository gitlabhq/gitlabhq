# frozen_string_literal: true

class CreateAuthenticationEventArchivedRecords < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  # rubocop:disable Migration/EnsureFactoryForTable -- there is no corresponding AR model for this temp table
  def up
    create_table :authentication_event_archived_records, id: false do |t|
      t.bigint :id, null: false
      t.datetime_with_timezone :created_at, null: false
      t.bigint :user_id
      t.integer :result, limit: 2, null: false
      t.inet :ip_address
      t.text :provider, null: false
      t.text :user_name, null: false
      t.datetime_with_timezone :archived_at, default: -> { 'CURRENT_TIMESTAMP' }
    end

    execute "ALTER TABLE authentication_event_archived_records ADD PRIMARY KEY (id)"

    add_text_limit :authentication_event_archived_records, :user_name, 255
    add_text_limit :authentication_event_archived_records, :provider, 64
  end
  # rubocop:enable Migration/EnsureFactoryForTable

  def down
    drop_table :authentication_event_archived_records
  end
end
