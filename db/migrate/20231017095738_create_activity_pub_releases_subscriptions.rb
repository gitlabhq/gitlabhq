# frozen_string_literal: true

class CreateActivityPubReleasesSubscriptions < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    create_table :activity_pub_releases_subscriptions do |t|
      t.references :project, index: false, foreign_key: { on_delete: :cascade }, null: false
      t.timestamps_with_timezone null: false
      t.integer :status, null: false, limit: 2, default: 1
      t.text :shared_inbox_url, limit: 1024
      t.text :subscriber_inbox_url, limit: 1024
      t.text :subscriber_url, limit: 1024, null: false
      t.jsonb :payload, null: true
      t.index 'project_id, LOWER(subscriber_url)', name: :index_activity_pub_releases_sub_on_project_id_sub_url,
        unique: true
      t.index 'project_id, LOWER(subscriber_inbox_url)',
        name: :index_activity_pub_releases_sub_on_project_id_inbox_url, unique: true
    end
  end

  def down
    drop_table :activity_pub_releases_subscriptions
  end
end
