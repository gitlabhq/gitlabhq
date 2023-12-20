# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropInProductMarketingEmails < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  def up
    drop_table :in_product_marketing_emails
  end

  def down
    create_table :in_product_marketing_emails do |t|
      t.bigint :user_id, null: false
      t.datetime_with_timezone :cta_clicked_at
      t.integer :track, null: false, limit: 2
      t.integer :series, null: false, limit: 2

      t.timestamps_with_timezone
    end

    add_index :in_product_marketing_emails, :user_id
    add_index :in_product_marketing_emails, %i[user_id track series], unique: true,
      name: 'index_in_product_marketing_emails_on_user_track_series'
    add_index :in_product_marketing_emails, %i[track series id cta_clicked_at],
      name: 'index_in_product_marketing_emails_on_track_series_id_clicked'
  end
end
