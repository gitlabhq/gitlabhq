# frozen_string_literal: true

class CreateMergeRequestReviewers < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    create_table :merge_request_reviewers do |t|
      t.bigint :user_id, null: false
      t.bigint :merge_request_id, null: false
      t.datetime_with_timezone :created_at, null: false
    end

    add_index :merge_request_reviewers, [:merge_request_id, :user_id], unique: true
    add_index :merge_request_reviewers, :user_id
  end

  def down
    drop_table :merge_request_reviewers
  end
end
