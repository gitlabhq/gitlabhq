# frozen_string_literal: true

class DropAuthenticationEventArchivedRecords < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.8'

  def up
    drop_table :authentication_event_archived_records, if_exists: true
  end

  def down
    return if table_exists?(:authentication_event_archived_records)

    # Same migration code as in the migration where the table was created:
    #   https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202447
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
end
