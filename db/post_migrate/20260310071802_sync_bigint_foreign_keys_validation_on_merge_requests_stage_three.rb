# frozen_string_literal: true

class SyncBigintForeignKeysValidationOnMergeRequestsStageThree < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.11'

  TABLE_NAME = 'merge_requests'
  COLUMNS = %i[id author_id].freeze
  FOREIGN_KEYS = [
    { source_table: :environments, column: :merge_request_id, name: :fk_01a033a308 },
    { source_table: :merge_request_assignment_events, column: :merge_request_id, name: :fk_08f7602bfd },
    { source_table: :scan_result_policy_violations, column: :merge_request_id, name: :fk_17ce579abf },
    { source_table: :merge_requests_compliance_violations, column: :merge_request_id, name: :fk_290ec1ab02 },
    { source_table: :approvals, column: :merge_request_id, name: :fk_310d714958 },
    { source_table: :agent_activity_events, column: :merge_request_id, name: :fk_3af186389b },
    { source_table: :merge_requests_approval_rules_merge_requests, column: :merge_request_id, name: :fk_74e3466397 },
    { source_table: :merge_request_diffs, column: :merge_request_id, name: :fk_8483f3258f },
    { source_table: :security_policy_dismissals, column: :merge_request_id, name: :fk_bc10da1827 },
    { source_table: :merge_requests, column: :author_id_convert_to_bigint, name: :fk_e719a85f8a },
    { source_table: :duo_workflows_workflows, column: :merge_request_id, name: :fk_ed58162ace },
    { source_table: :status_check_responses, column: :merge_request_id, name: :fk_f3953d86c6 },
    { source_table: :approval_policy_merge_request_bypass_events, column: :merge_request_id, name: :fk_f39e177609 },
    { source_table: :approval_merge_request_rules, column: :merge_request_id, name: :fk_rails_004ce82224 },
    { source_table: :merge_request_context_commits, column: :merge_request_id, name: :fk_rails_0fe0039f60 },
    { source_table: :description_versions, column: :merge_request_id, name: :fk_rails_12b144011c },
    { source_table: :resource_state_events, column: :merge_request_id, name: :fk_rails_3112bba7dc },
    { source_table: :merge_request_blocks, column: :blocked_merge_request_id, name: :fk_rails_364d4bea8b },
    { source_table: :merge_request_assignees, column: :merge_request_id, name: :fk_rails_443443ce6f },
    { source_table: :merge_requests_closing_issues, column: :merge_request_id, name: :fk_rails_458eda8667 },
    { source_table: :merge_request_merge_schedules, column: :merge_request_id, name: :fk_rails_5294434bc3 },
    { source_table: :reviews, column: :merge_request_id, name: :fk_rails_5ca11d8c31 },
    { source_table: :merge_request_approval_metrics, column: :merge_request_id, name: :fk_rails_5cb1ca73f8 },
    { source_table: :resource_iteration_events, column: :merge_request_id, name: :fk_rails_6830c13ac1 },
    { source_table: :resource_state_events, column: :source_merge_request_id, name: :fk_rails_7ddc5f7457 },
    { source_table: :deployment_merge_requests, column: :merge_request_id, name: :fk_rails_86a6d8bf12 },
    { source_table: :excluded_merge_requests, column: :merge_request_id, name: :fk_rails_8c973feffa },
    { source_table: :merge_request_cleanup_schedules, column: :merge_request_id, name: :fk_rails_92dd0e705c },
    { source_table: :resource_label_events, column: :merge_request_id, name: :fk_rails_9851a00031 },
    { source_table: :resource_milestone_events, column: :merge_request_id, name: :fk_rails_a006df5590 },
    { source_table: :merge_request_user_mentions, column: :merge_request_id, name: :fk_rails_aa1b2961b1 },
    { source_table: :merge_trains, column: :merge_request_id, name: :fk_rails_b374b5225d },
    { source_table: :merge_request_predictions, column: :merge_request_id, name: :fk_rails_b3b78cbcd0 },
    { source_table: :merge_request_reviewers, column: :merge_request_id, name: :fk_rails_d9fec24b9d },
    { source_table: :merge_request_metrics, column: :merge_request_id, name: :fk_rails_e6d7c24d1b },
    { source_table: :draft_notes, column: :merge_request_id, name: :fk_rails_e753681674 },
    { source_table: :merge_request_blocks, column: :blocking_merge_request_id, name: :fk_rails_e9387863bc },
    { source_table: :timelogs, column: :merge_request_id, name: :fk_timelogs_merge_requests_merge_request_id }
  ].freeze
  PARTITIONED_FOREIGN_KEYS = [
    {
      source_table: :merge_requests_merge_data,
      column: :merge_request_id,
      target_table: :merge_requests,
      target_column: :id_convert_to_bigint,
      on_delete: :cascade,
      name: :fk_rails_593f9b7924,
      reverse_lock_order: true
    }
  ].freeze

  def up
    conversion_needed = COLUMNS.all? do |column|
      column_exists?(TABLE_NAME, convert_to_bigint_column(column))
    end

    unless conversion_needed
      say "No conversion columns found - no need to validate bigint FKs"
      return
    end

    # synchronously validates un-partitioned FKs
    FOREIGN_KEYS.each do |fk|
      validate_foreign_key fk[:source_table], fk[:column], name: tmp_name(fk[:name])
    end

    # synchronously validates partitioned FKs
    PARTITIONED_FOREIGN_KEYS.each do |fk|
      add_concurrent_partitioned_foreign_key(
        fk[:source_table],
        fk[:target_table],
        column: fk[:column],
        target_column: fk[:target_column],
        name: tmp_name(fk[:name]),
        on_delete: fk[:on_delete],
        validate: true,
        reverse_lock_order: fk[:reverse_lock_order]
      )
    end
  end

  def down
    # no-op
  end

  private

  def tmp_name(name)
    "#{name}_tmp"
  end
end
