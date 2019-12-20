# frozen_string_literal: true

class CreateGitlabSubscriptionHistories < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    create_table :gitlab_subscription_histories do |t|
      t.datetime_with_timezone :gitlab_subscription_created_at
      t.datetime_with_timezone :gitlab_subscription_updated_at
      t.date :start_date
      t.date :end_date
      t.date :trial_ends_on
      t.integer :namespace_id, null: true
      t.integer :hosted_plan_id, null: true
      t.integer :max_seats_used
      t.integer :seats
      t.boolean :trial
      t.integer :change_type, limit: 2
      t.bigint :gitlab_subscription_id, null: false
      t.datetime_with_timezone :created_at
    end
    add_index :gitlab_subscription_histories, :gitlab_subscription_id
  end

  def down
    drop_table :gitlab_subscription_histories
  end
end
