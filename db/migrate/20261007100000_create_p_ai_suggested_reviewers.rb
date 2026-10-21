# frozen_string_literal: true

class CreatePAiSuggestedReviewers < Gitlab::Database::Migration[2.4]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  milestone '19.6'

  OPTIONS = {
    primary_key: [:id, :created_at],
    options: 'PARTITION BY RANGE (created_at)',
    if_not_exists: true
  }.freeze

  RETENTION_PERIOD = 30.days

  def up
    create_table :p_ai_suggested_reviewers, **OPTIONS do |t|
      t.bigserial :id, null: false
      t.bigint :project_id, null: false
      t.bigint :merge_request_id, null: false
      t.bigint :user_id, null: false
      t.bigint :approval_merge_request_rule_id
      t.bigint :approval_project_rule_id
      t.timestamps_with_timezone null: false
      t.text :reason, null: true, limit: 2048

      t.index [:merge_request_id, :user_id, :created_at], unique: true,
        name: 'index_p_ai_suggested_reviewers_on_mr_id_user_id_created_at'
      t.index :user_id, name: 'index_p_ai_suggested_reviewers_on_user_id'
      t.index :project_id, name: 'index_p_ai_suggested_reviewers_on_project_id'
      t.index :approval_merge_request_rule_id, name: 'index_p_ai_suggested_reviewers_on_approval_mr_rule_id'
      t.index :approval_project_rule_id, name: 'index_p_ai_suggested_reviewers_on_approval_project_rule_id'
    end

    add_check_constraint(
      :p_ai_suggested_reviewers,
      'num_nonnulls(approval_merge_request_rule_id, approval_project_rule_id) <= 1',
      'check_p_ai_suggested_reviewers_one_approval_rule'
    )

    create_daily_partitions
  end

  def down
    drop_table :p_ai_suggested_reviewers
  end

  private

  def create_daily_partitions
    today = Time.now.utc.to_date

    ((today - RETENTION_PERIOD)..today).each do |date|
      create_range_partition_safely(
        "p_ai_suggested_reviewers_#{date.strftime('%Y%m%d')}",
        :p_ai_suggested_reviewers,
        connection.quote(date.iso8601),
        connection.quote(date.next_day.iso8601)
      )
    end
  end
end
