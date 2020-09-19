# frozen_string_literal: true

class CreateAuthenticationEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:authentication_events)
      with_lock_retries do
        create_table :authentication_events do |t|
          t.datetime_with_timezone :created_at, null: false
          t.references :user, foreign_key: { on_delete: :nullify }, index: true
          t.integer :result, limit: 2, null: false
          t.inet :ip_address
          t.text :provider, null: false, index: true
          t.text :user_name, null: false
        end
      end
    end

    add_text_limit :authentication_events, :provider, 64
    add_text_limit :authentication_events, :user_name, 255
  end

  def down
    with_lock_retries do
      drop_table :authentication_events
    end
  end
end
