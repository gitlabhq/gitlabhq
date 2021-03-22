# frozen_string_literal: true

class CreateInProductMarketingEmails < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  UNIQUE_INDEX_NAME = 'index_in_product_marketing_emails_on_user_track_series'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      create_table :in_product_marketing_emails do |t|
        t.bigint :user_id, null: false
        t.datetime_with_timezone :cta_clicked_at
        t.integer :track, null: false, limit: 2
        t.integer :series, null: false, limit: 2

        t.timestamps_with_timezone
      end
    end

    add_index :in_product_marketing_emails, :user_id
    add_index :in_product_marketing_emails, [:user_id, :track, :series], unique: true, name: UNIQUE_INDEX_NAME
  end

  def down
    with_lock_retries do
      drop_table :in_product_marketing_emails
    end
  end
end
