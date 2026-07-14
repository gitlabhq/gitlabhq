# frozen_string_literal: true

class AddSiphonWatermarkColumnToSiphonTables < ClickHouse::Migration
  TABLES = %w[
    merge_requests
    siphon_approvals
    siphon_award_emoji
    siphon_banned_users
    siphon_ci_pipeline_metadata
    siphon_ci_runners
    siphon_ci_sources_pipelines
    siphon_container_repositories
    siphon_deployment_merge_requests
    siphon_deployments
    siphon_duo_workflows_workflows
    siphon_environments
    siphon_events
    siphon_issue_assignees
    siphon_issue_links
    siphon_issue_metrics
    siphon_knowledge_graph_enabled_namespaces
    siphon_label_links
    siphon_labels
    siphon_members
    siphon_merge_request_assignees
    siphon_merge_request_diff_files
    siphon_merge_request_diffs
    siphon_merge_request_metrics
    siphon_merge_request_reviewers
    siphon_merge_requests_closing_issues
    siphon_milestones
    siphon_namespace_details
    siphon_namespaces
    siphon_notes
    siphon_organizations
    siphon_p_ci_builds
    siphon_p_ci_pipelines
    siphon_p_ci_stages
    siphon_packages_build_infos
    siphon_packages_packages
    siphon_project_authorizations
    siphon_projects
    siphon_routes
    siphon_security_findings
    siphon_security_scans
    siphon_system_note_metadata
    siphon_users
    siphon_vulnerabilities
    siphon_vulnerability_identifiers
    siphon_vulnerability_merge_request_links
    siphon_vulnerability_occurrence_identifiers
    siphon_vulnerability_occurrences
    siphon_vulnerability_scanners
    siphon_work_item_current_statuses
    siphon_work_item_parent_links
    work_items
  ].freeze

  def up
    # rubocop: disable Layout/LineLength -- long statement
    TABLES.each do |table|
      execute("ALTER TABLE #{table} ADD COLUMN IF NOT EXISTS _siphon_watermark DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1))")
      execute("ALTER TABLE #{table} ADD INDEX IF NOT EXISTS idx_siphon_watermark_minmax _siphon_watermark TYPE minmax GRANULARITY 1")
      execute("ALTER TABLE #{table} MATERIALIZE COLUMN _siphon_watermark SETTINGS mutations_sync = 0")
      execute("ALTER TABLE #{table} MATERIALIZE INDEX idx_siphon_watermark_minmax SETTINGS mutations_sync = 0")
    end
    # rubocop: enable Layout/LineLength
  end

  def down
    TABLES.each do |table|
      execute("ALTER TABLE #{table} DROP INDEX IF EXISTS idx_siphon_watermark_minmax")
      execute("ALTER TABLE #{table} DROP COLUMN IF EXISTS _siphon_watermark")
    end
  end
end
