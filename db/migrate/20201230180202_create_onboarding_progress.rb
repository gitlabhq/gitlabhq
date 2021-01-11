# frozen_string_literal: true

class CreateOnboardingProgress < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      create_table :onboarding_progresses do |t|
        t.references :namespace, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
        t.timestamps_with_timezone null: false
        t.datetime_with_timezone :git_pull_at
        t.datetime_with_timezone :git_write_at
        t.datetime_with_timezone :merge_request_created_at
        t.datetime_with_timezone :pipeline_created_at
        t.datetime_with_timezone :user_added_at
        t.datetime_with_timezone :trial_started_at
        t.datetime_with_timezone :subscription_created_at
        t.datetime_with_timezone :required_mr_approvals_enabled_at
        t.datetime_with_timezone :code_owners_enabled_at
        t.datetime_with_timezone :scoped_label_created_at
        t.datetime_with_timezone :security_scan_enabled_at
        t.datetime_with_timezone :issue_auto_closed_at
        t.datetime_with_timezone :repository_imported_at
        t.datetime_with_timezone :repository_mirrored_at
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :onboarding_progresses
    end
  end
end
