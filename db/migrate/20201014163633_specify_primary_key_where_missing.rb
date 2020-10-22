# frozen_string_literal: true

class SpecifyPrimaryKeyWhereMissing < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  TABLES = {
    project_authorizations: [:index_project_authorizations_on_user_id_project_id_access_level, %i(user_id project_id access_level)],
    analytics_language_trend_repository_languages: [:analytics_repository_languages_unique_index, %i(programming_language_id project_id snapshot_date)],
    approval_project_rules_protected_branches: [:index_approval_project_rules_protected_branches_unique, %i(approval_project_rule_id protected_branch_id)],
    ci_build_trace_sections: [:index_ci_build_trace_sections_on_build_id_and_section_name_id, %i(build_id section_name_id)],
    deployment_merge_requests: [:idx_deployment_merge_requests_unique_index, %i(deployment_id merge_request_id)],
    issue_assignees: [:index_issue_assignees_on_issue_id_and_user_id, %i(issue_id user_id)],
    issues_prometheus_alert_events: [:issue_id_prometheus_alert_event_id_index, %i(issue_id prometheus_alert_event_id)],
    issues_self_managed_prometheus_alert_events: [:issue_id_self_managed_prometheus_alert_event_id_index, %i(issue_id self_managed_prometheus_alert_event_id)],
    merge_request_diff_commits: [:index_merge_request_diff_commits_on_mr_diff_id_and_order, %i(merge_request_diff_id relative_order)],
    merge_request_diff_files: [:index_merge_request_diff_files_on_mr_diff_id_and_order, %i(merge_request_diff_id relative_order)],
    milestone_releases: [:index_miletone_releases_on_milestone_and_release, %i(milestone_id release_id)],
    project_pages_metadata: [:index_project_pages_metadata_on_project_id, %i(project_id)],
    push_event_payloads: [:index_push_event_payloads_on_event_id, %i(event_id)],
    repository_languages: [:index_repository_languages_on_project_and_languages_id, %i(project_id programming_language_id)],
    user_interacted_projects: [:index_user_interacted_projects_on_project_id_and_user_id, %i(project_id user_id)],
    users_security_dashboard_projects: [:users_security_dashboard_projects_unique_index, %i(project_id user_id)]
  }.freeze

  def up
    TABLES.each do |table, (unique_index, _)|
      with_lock_retries do
        execute "ALTER TABLE #{table} ADD CONSTRAINT #{table}_pkey PRIMARY KEY USING INDEX #{unique_index}" if index_exists_by_name?(table, unique_index)
      end
    end
  end

  def down
    TABLES.each do |table, (unique_index, columns)|
      add_concurrent_index table, columns, name: unique_index, unique: true

      with_lock_retries do
        execute "ALTER TABLE #{table} DROP CONSTRAINT #{table}_pkey"
      end
    end
  end
end
