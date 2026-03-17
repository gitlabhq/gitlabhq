# frozen_string_literal: true

class DropOldMergeRequestsTables < ClickHouse::Migration
  def up
    execute 'DROP VIEW IF EXISTS hierarchy_merge_requests_mv'
    execute 'DROP VIEW IF EXISTS merge_request_label_links_mv'
    execute 'DROP VIEW IF EXISTS hierarchy_work_items_mv'
    execute 'DROP VIEW IF EXISTS work_item_label_links_mv'
    execute 'DROP VIEW IF EXISTS work_item_award_emoji_aggregations_mv'
    execute 'DROP VIEW IF EXISTS work_item_award_emoji_trigger_mv'
    execute 'DROP VIEW IF EXISTS work_item_award_emoji_mv'
    execute 'DROP TABLE IF EXISTS hierarchy_merge_requests'
    execute 'DROP TABLE IF EXISTS siphon_merge_requests'
    execute 'DROP TABLE IF EXISTS merge_request_label_links'
    execute 'DROP TABLE IF EXISTS siphon_approvals'
    execute 'DROP TABLE IF EXISTS siphon_merge_request_assignees'
    execute 'DROP TABLE IF EXISTS siphon_merge_request_metrics'
    execute 'DROP TABLE IF EXISTS siphon_label_links'
    execute 'DROP TABLE IF EXISTS work_item_label_links'
    execute 'DROP TABLE IF EXISTS work_item_award_emoji_aggregations'
    execute 'DROP TABLE IF EXISTS work_item_award_emoji_trigger'
    execute 'DROP TABLE IF EXISTS work_item_award_emoji'
    execute 'DROP TABLE IF EXISTS siphon_award_emoji'
  end

  def down
    execute <<~SQL
      CREATE TABLE hierarchy_merge_requests
      (
          `traversal_path` String,
          `id` Int64,
          `target_branch` String,
          `source_branch` String,
          `source_project_id` Nullable(Int64),
          `author_id` Nullable(Int64),
          `assignee_id` Nullable(Int64),
          `title` String DEFAULT '',
          `created_at` DateTime64(6, 'UTC') DEFAULT now(),
          `updated_at` DateTime64(6, 'UTC') DEFAULT now(),
          `milestone_id` Nullable(Int64),
          `merge_status` LowCardinality(String) DEFAULT 'unchecked',
          `target_project_id` Int64,
          `iid` Nullable(Int64),
          `description` String DEFAULT '',
          `updated_by_id` Nullable(Int64),
          `merge_error` Nullable(String),
          `merge_params` Nullable(String),
          `merge_when_pipeline_succeeds` Bool DEFAULT false,
          `merge_user_id` Nullable(Int64),
          `merge_commit_sha` Nullable(String),
          `approvals_before_merge` Nullable(Int64),
          `rebase_commit_sha` Nullable(String),
          `in_progress_merge_commit_sha` Nullable(String),
          `lock_version` Int64 DEFAULT 0,
          `time_estimate` Nullable(Int64) DEFAULT 0,
          `squash` Bool DEFAULT false,
          `cached_markdown_version` Nullable(Int64),
          `last_edited_at` Nullable(DateTime64(6, 'UTC')),
          `last_edited_by_id` Nullable(Int64),
          `merge_jid` Nullable(String),
          `discussion_locked` Nullable(Bool),
          `latest_merge_request_diff_id` Nullable(Int64),
          `allow_maintainer_to_push` Nullable(Bool) DEFAULT true,
          `state_id` Int8 DEFAULT 1,
          `rebase_jid` Nullable(String),
          `squash_commit_sha` Nullable(String),
          `sprint_id` Nullable(Int64),
          `merge_ref_sha` Nullable(String),
          `draft` Bool DEFAULT false,
          `prepared_at` Nullable(DateTime64(6, 'UTC')),
          `merged_commit_sha` Nullable(String),
          `override_requested_changes` Bool DEFAULT false,
          `head_pipeline_id` Nullable(Int64),
          `imported_from` Int8 DEFAULT 0,
          `retargeted` Bool DEFAULT false,
          `label_ids` String DEFAULT '',
          `assignee_ids` String DEFAULT '',
          `approver_ids` String DEFAULT '',
          `metric_latest_build_started_at` Nullable(DateTime64(6, 'UTC')),
          `metric_latest_build_finished_at` Nullable(DateTime64(6, 'UTC')),
          `metric_first_deployed_to_production_at` Nullable(DateTime64(6, 'UTC')),
          `metric_merged_at` Nullable(DateTime64(6, 'UTC')),
          `metric_merged_by_id` Nullable(Int64),
          `metric_latest_closed_by_id` Nullable(Int64),
          `metric_latest_closed_at` Nullable(DateTime64(6, 'UTC')),
          `metric_first_comment_at` Nullable(DateTime64(6, 'UTC')),
          `metric_first_commit_at` Nullable(DateTime64(6, 'UTC')),
          `metric_last_commit_at` Nullable(DateTime64(6, 'UTC')),
          `metric_diff_size` Nullable(Int64),
          `metric_modified_paths_size` Nullable(Int64),
          `metric_commits_count` Nullable(Int64),
          `metric_first_approved_at` Nullable(DateTime64(6, 'UTC')),
          `metric_first_reassigned_at` Nullable(DateTime64(6, 'UTC')),
          `metric_added_lines` Nullable(Int64),
          `metric_removed_lines` Nullable(Int64),
          `metric_first_contribution` Bool DEFAULT false,
          `metric_pipeline_id` Nullable(Int64),
          `metric_reviewer_first_assigned_at` Nullable(DateTime64(6, 'UTC')),
          `version` DateTime64(6, 'UTC') DEFAULT now(),
          `deleted` Bool DEFAULT false
      )
      ENGINE = ReplacingMergeTree(version, deleted)
      PRIMARY KEY (traversal_path, id)
      ORDER BY (traversal_path, id)
      SETTINGS index_granularity = 8192;
    SQL

    execute <<~SQL
      CREATE TABLE siphon_merge_requests
      (
          `id` Int64,
          `target_branch` String,
          `source_branch` String,
          `source_project_id` Nullable(Int64),
          `author_id` Nullable(Int64),
          `assignee_id` Nullable(Int64),
          `title` String DEFAULT '',
          `created_at` DateTime64(6, 'UTC') DEFAULT now(),
          `updated_at` DateTime64(6, 'UTC') DEFAULT now(),
          `milestone_id` Nullable(Int64),
          `merge_status` LowCardinality(String) DEFAULT 'unchecked',
          `target_project_id` Int64,
          `iid` Nullable(Int64),
          `description` String DEFAULT '',
          `updated_by_id` Nullable(Int64),
          `merge_error` Nullable(String),
          `merge_params` Nullable(String),
          `merge_when_pipeline_succeeds` Bool DEFAULT false,
          `merge_user_id` Nullable(Int64),
          `merge_commit_sha` Nullable(String),
          `approvals_before_merge` Nullable(Int64),
          `rebase_commit_sha` Nullable(String),
          `in_progress_merge_commit_sha` Nullable(String),
          `lock_version` Int64 DEFAULT 0,
          `time_estimate` Nullable(Int64) DEFAULT 0,
          `squash` Bool DEFAULT false,
          `cached_markdown_version` Nullable(Int64),
          `last_edited_at` Nullable(DateTime64(6, 'UTC')),
          `last_edited_by_id` Nullable(Int64),
          `merge_jid` Nullable(String),
          `discussion_locked` Nullable(Bool),
          `latest_merge_request_diff_id` Nullable(Int64),
          `allow_maintainer_to_push` Nullable(Bool) DEFAULT true,
          `state_id` Int8 DEFAULT 1,
          `rebase_jid` Nullable(String),
          `squash_commit_sha` Nullable(String),
          `sprint_id` Nullable(Int64),
          `merge_ref_sha` Nullable(String),
          `draft` Bool DEFAULT false,
          `prepared_at` Nullable(DateTime64(6, 'UTC')),
          `merged_commit_sha` Nullable(String),
          `override_requested_changes` Bool DEFAULT false,
          `head_pipeline_id` Nullable(Int64),
          `imported_from` Int8 DEFAULT 0,
          `retargeted` Bool DEFAULT false,
          `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now(),
          `_siphon_deleted` Bool DEFAULT false
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY id
      ORDER BY id
      SETTINGS index_granularity = 8192;
    SQL

    execute <<~SQL
      CREATE TABLE merge_request_label_links
      (
          `id` Int64,
          `label_id` Int64,
          `merge_request_id` Int64,
          `created_at` DateTime64(6, 'UTC'),
          `updated_at` DateTime64(6, 'UTC'),
          `version` DateTime64(6, 'UTC') DEFAULT now(),
          `deleted` Bool DEFAULT false
      )
      ENGINE = ReplacingMergeTree(version, deleted)
      PRIMARY KEY (merge_request_id, label_id, id)
      ORDER BY (merge_request_id, label_id, id)
      SETTINGS index_granularity = 8192;
    SQL

    execute <<~SQL
      CREATE TABLE siphon_approvals
      (
          `id` Int64,
          `merge_request_id` Int64,
          `user_id` Int64,
          `created_at` DateTime64(6, 'UTC'),
          `updated_at` DateTime64(6, 'UTC'),
          `patch_id_sha` String DEFAULT '',
          `project_id` Int64,
          `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now(),
          `_siphon_deleted` Bool DEFAULT false
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (merge_request_id, id)
      ORDER BY (merge_request_id, id)
      SETTINGS index_granularity = 8192;
    SQL

    execute <<~SQL
      CREATE TABLE siphon_merge_request_assignees
      (
          `id` Int64,
          `user_id` Int64,
          `merge_request_id` Int64,
          `created_at` DateTime64(6, 'UTC'),
          `project_id` Int64,
          `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now(),
          `_siphon_deleted` Bool DEFAULT false
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (merge_request_id, id)
      ORDER BY (merge_request_id, id)
      SETTINGS index_granularity = 8192;
    SQL

    execute <<~SQL
      CREATE TABLE siphon_merge_request_metrics
      (
          `merge_request_id` Int64,
          `latest_build_started_at` Nullable(DateTime64(6, 'UTC')),
          `latest_build_finished_at` Nullable(DateTime64(6, 'UTC')),
          `first_deployed_to_production_at` Nullable(DateTime64(6, 'UTC')),
          `merged_at` Nullable(DateTime64(6, 'UTC')),
          `created_at` DateTime64(6, 'UTC'),
          `updated_at` DateTime64(6, 'UTC'),
          `merged_by_id` Nullable(Int64),
          `latest_closed_by_id` Nullable(Int64),
          `latest_closed_at` Nullable(DateTime64(6, 'UTC')),
          `first_comment_at` Nullable(DateTime64(6, 'UTC')),
          `first_commit_at` Nullable(DateTime64(6, 'UTC')),
          `last_commit_at` Nullable(DateTime64(6, 'UTC')),
          `diff_size` Nullable(Int64),
          `modified_paths_size` Nullable(Int64),
          `commits_count` Nullable(Int64),
          `first_approved_at` Nullable(DateTime64(6, 'UTC')),
          `first_reassigned_at` Nullable(DateTime64(6, 'UTC')),
          `added_lines` Nullable(Int64),
          `removed_lines` Nullable(Int64),
          `target_project_id` Nullable(Int64),
          `id` Int64,
          `first_contribution` Bool DEFAULT false,
          `pipeline_id` Nullable(Int64),
          `reviewer_first_assigned_at` Nullable(DateTime64(6, 'UTC')),
          `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now(),
          `_siphon_deleted` Bool DEFAULT false
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (merge_request_id, id)
      ORDER BY (merge_request_id, id)
      SETTINGS index_granularity = 8192;
    SQL

    execute <<~SQL
      CREATE TABLE siphon_label_links
      (
          `id` Int64,
          `label_id` Nullable(Int64),
          `target_id` Nullable(Int64),
          `target_type` Nullable(String),
          `created_at` DateTime64(6, 'UTC') DEFAULT now(),
          `updated_at` DateTime64(6, 'UTC') DEFAULT now(),
          `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now(),
          `_siphon_deleted` Bool DEFAULT false,
          `namespace_id` Int64
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY id
      ORDER BY id
      SETTINGS index_granularity = 8192;
    SQL

    execute <<~SQL
      CREATE TABLE work_item_label_links
      (
          `id` Int64,
          `label_id` Int64,
          `work_item_id` Int64,
          `created_at` DateTime64(6, 'UTC'),
          `updated_at` DateTime64(6, 'UTC'),
          `version` DateTime64(6, 'UTC') DEFAULT now(),
          `deleted` Bool DEFAULT false
      )
      ENGINE = ReplacingMergeTree(version, deleted)
      PRIMARY KEY (work_item_id, label_id, id)
      ORDER BY (work_item_id, label_id, id)
      SETTINGS index_granularity = 8192;
    SQL

    execute <<~SQL
      CREATE TABLE work_item_award_emoji_aggregations
      (
          `work_item_id` Int64,
          `counts_by_emoji` Map(LowCardinality(String), UInt32),
          `user_ids_by_emoji` Map(LowCardinality(String), String),
          `version` DateTime64(6, 'UTC') DEFAULT now(),
          `deleted` Bool DEFAULT false
      )
      ENGINE = ReplacingMergeTree(version, deleted)
      PRIMARY KEY work_item_id
      ORDER BY work_item_id
      SETTINGS index_granularity = 8192;
    SQL

    execute <<~SQL
      CREATE TABLE work_item_award_emoji_trigger
      (
          `work_item_id` Int64,
          `version` DateTime64(6, 'UTC') DEFAULT now(),
          `deleted` Bool DEFAULT false
      )
      ENGINE = ReplacingMergeTree(version, deleted)
      PRIMARY KEY work_item_id
      ORDER BY work_item_id
      SETTINGS index_granularity = 8192;
    SQL

    execute <<~SQL
      CREATE TABLE work_item_award_emoji
      (
          `work_item_id` Int64,
          `id` Int64,
          `name` LowCardinality(String),
          `user_id` Int64,
          `created_at` DateTime64(6, 'UTC'),
          `updated_at` DateTime64(6, 'UTC'),
          `version` DateTime64(6, 'UTC') DEFAULT now(),
          `deleted` Bool DEFAULT false
      )
      ENGINE = ReplacingMergeTree(version, deleted)
      PRIMARY KEY (work_item_id, id)
      ORDER BY (work_item_id, id)
      SETTINGS index_granularity = 8192;
    SQL

    execute <<~SQL
      CREATE TABLE siphon_award_emoji
      (
          `id` Int64,
          `name` LowCardinality(String),
          `user_id` Int64,
          `awardable_type` String,
          `awardable_id` Int64,
          `created_at` DateTime64(6, 'UTC'),
          `updated_at` DateTime64(6, 'UTC'),
          `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now(),
          `_siphon_deleted` Bool DEFAULT false,
          `namespace_id` Nullable(Int64),
          `organization_id` Nullable(Int64)
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY id
      ORDER BY id
      SETTINGS index_granularity = 8192;
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW merge_request_label_links_mv TO merge_request_label_links
      (
          `id` Int64,
          `label_id` Nullable(Int64),
          `merge_request_id` Nullable(Int64),
          `created_at` DateTime64(6, 'UTC'),
          `updated_at` DateTime64(6, 'UTC'),
          `version` DateTime64(6, 'UTC'),
          `deleted` Bool
      )
      AS SELECT
          id,
          label_id,
          target_id AS merge_request_id,
          created_at,
          updated_at,
          _siphon_replicated_at AS version,
          _siphon_deleted AS deleted
      FROM siphon_label_links
      WHERE (target_type = 'MergeRequest') AND (target_id IS NOT NULL) AND (label_id IS NOT NULL);
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW work_item_label_links_mv TO work_item_label_links
      (
          `id` Int64,
          `label_id` Nullable(Int64),
          `work_item_id` Nullable(Int64),
          `created_at` DateTime64(6, 'UTC'),
          `updated_at` DateTime64(6, 'UTC'),
          `version` DateTime64(6, 'UTC'),
          `deleted` Bool
      )
      AS SELECT
          id,
          label_id,
          target_id AS work_item_id,
          created_at,
          updated_at,
          _siphon_replicated_at AS version,
          _siphon_deleted AS deleted
      FROM siphon_label_links
      WHERE (target_type = 'Issue') AND (target_id IS NOT NULL) AND (label_id IS NOT NULL);
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW hierarchy_merge_requests_mv TO hierarchy_merge_requests
      (
          `traversal_path` String,
          `id` Int64,
          `target_branch` String,
          `source_branch` String,
          `source_project_id` Nullable(Int64),
          `author_id` Nullable(Int64),
          `assignee_id` Nullable(Int64),
          `title` String,
          `created_at` DateTime64(6, 'UTC'),
          `updated_at` DateTime64(6, 'UTC'),
          `milestone_id` Nullable(Int64),
          `merge_status` LowCardinality(String),
          `target_project_id` Int64,
          `iid` Nullable(Int64),
          `description` String,
          `updated_by_id` Nullable(Int64),
          `merge_error` Nullable(String),
          `merge_params` Nullable(String),
          `merge_when_pipeline_succeeds` Bool,
          `merge_user_id` Nullable(Int64),
          `merge_commit_sha` Nullable(String),
          `approvals_before_merge` Nullable(Int64),
          `rebase_commit_sha` Nullable(String),
          `in_progress_merge_commit_sha` Nullable(String),
          `lock_version` Int64,
          `time_estimate` Nullable(Int64),
          `squash` Bool,
          `cached_markdown_version` Nullable(Int64),
          `last_edited_at` Nullable(DateTime64(6, 'UTC')),
          `last_edited_by_id` Nullable(Int64),
          `merge_jid` Nullable(String),
          `discussion_locked` Nullable(Bool),
          `latest_merge_request_diff_id` Nullable(Int64),
          `allow_maintainer_to_push` Nullable(Bool),
          `state_id` Int8,
          `rebase_jid` Nullable(String),
          `squash_commit_sha` Nullable(String),
          `sprint_id` Nullable(Int64),
          `merge_ref_sha` Nullable(String),
          `draft` Bool,
          `prepared_at` Nullable(DateTime64(6, 'UTC')),
          `merged_commit_sha` Nullable(String),
          `override_requested_changes` Bool,
          `head_pipeline_id` Nullable(Int64),
          `imported_from` Int8,
          `retargeted` Bool,
          `version` DateTime64(6, 'UTC'),
          `deleted` Bool,
          `label_ids` String,
          `assignee_ids` String,
          `approver_ids` String,
          `metric_latest_build_started_at` Nullable(DateTime64(6, 'UTC')),
          `metric_latest_build_finished_at` Nullable(DateTime64(6, 'UTC')),
          `metric_first_deployed_to_production_at` Nullable(DateTime64(6, 'UTC')),
          `metric_merged_at` Nullable(DateTime64(6, 'UTC')),
          `metric_merged_by_id` Nullable(Int64),
          `metric_latest_closed_by_id` Nullable(Int64),
          `metric_latest_closed_at` Nullable(DateTime64(6, 'UTC')),
          `metric_first_comment_at` Nullable(DateTime64(6, 'UTC')),
          `metric_first_commit_at` Nullable(DateTime64(6, 'UTC')),
          `metric_last_commit_at` Nullable(DateTime64(6, 'UTC')),
          `metric_diff_size` Nullable(Int64),
          `metric_modified_paths_size` Nullable(Int64),
          `metric_commits_count` Nullable(Int64),
          `metric_first_approved_at` Nullable(DateTime64(6, 'UTC')),
          `metric_first_reassigned_at` Nullable(DateTime64(6, 'UTC')),
          `metric_added_lines` Nullable(Int64),
          `metric_removed_lines` Nullable(Int64),
          `metric_first_contribution` Bool,
          `metric_pipeline_id` Nullable(Int64),
          `metric_reviewer_first_assigned_at` Nullable(DateTime64(6, 'UTC'))
      )
      AS WITH
          cte AS
          (
              SELECT *
              FROM siphon_merge_requests
          ),
          project_namespace_paths AS
          (
              SELECT *
              FROM
              (
                  SELECT
                      id,
                      argMax(traversal_path, version) AS traversal_path,
                      argMax(deleted, version) AS deleted
                  FROM project_namespace_traversal_paths
                  WHERE id IN (
                      SELECT DISTINCT target_project_id
                      FROM cte
                  )
                  GROUP BY id
              )
              WHERE deleted = false
          ),
          collected_label_ids AS
          (
              SELECT
                  merge_request_id,
                  concat('/', arrayStringConcat(arraySort(groupArray(label_id)), '/'), '/') AS label_ids
              FROM
              (
                  SELECT
                      merge_request_id,
                      label_id,
                      id,
                      argMax(deleted, version) AS deleted
                  FROM merge_request_label_links
                  WHERE merge_request_id IN (
                      SELECT id
                      FROM cte
                  )
                  GROUP BY
                      merge_request_id,
                      label_id,
                      id
              )
              WHERE deleted = false
              GROUP BY merge_request_id
          ),
          collected_assignee_ids AS
          (
              SELECT
                  merge_request_id,
                  concat('/', arrayStringConcat(arraySort(groupArray(user_id)), '/'), '/') AS user_ids
              FROM
              (
                  SELECT
                      merge_request_id,
                      user_id,
                      argMax(_siphon_deleted, _siphon_replicated_at) AS _siphon_deleted
                  FROM siphon_merge_request_assignees
                  WHERE merge_request_id IN (
                      SELECT id
                      FROM cte
                  )
                  GROUP BY
                      merge_request_id,
                      user_id
              )
              WHERE _siphon_deleted = false
              GROUP BY merge_request_id
          ),
          collected_approver_ids AS
          (
              SELECT
                  merge_request_id,
                  concat('/', arrayStringConcat(arraySort(groupArray(user_id)), '/'), '/') AS user_ids
              FROM
              (
                  SELECT
                      merge_request_id,
                      user_id,
                      argMax(_siphon_deleted, _siphon_replicated_at) AS _siphon_deleted
                  FROM siphon_approvals
                  WHERE merge_request_id IN (
                      SELECT id
                      FROM cte
                  )
                  GROUP BY
                      merge_request_id,
                      user_id
              )
              WHERE _siphon_deleted = false
              GROUP BY merge_request_id
          ),
          collected_merge_request_metrics AS
          (
              SELECT *
              FROM
              (
                  SELECT
                      merge_request_id,
                      argMax(latest_build_started_at, _siphon_replicated_at) AS latest_build_started_at,
                      argMax(latest_build_finished_at, _siphon_replicated_at) AS latest_build_finished_at,
                      argMax(first_deployed_to_production_at, _siphon_replicated_at) AS first_deployed_to_production_at,
                      argMax(merged_at, _siphon_replicated_at) AS merged_at,
                      argMax(merged_by_id, _siphon_replicated_at) AS merged_by_id,
                      argMax(latest_closed_by_id, _siphon_replicated_at) AS latest_closed_by_id,
                      argMax(latest_closed_at, _siphon_replicated_at) AS latest_closed_at,
                      argMax(first_comment_at, _siphon_replicated_at) AS first_comment_at,
                      argMax(first_commit_at, _siphon_replicated_at) AS first_commit_at,
                      argMax(last_commit_at, _siphon_replicated_at) AS last_commit_at,
                      argMax(diff_size, _siphon_replicated_at) AS diff_size,
                      argMax(modified_paths_size, _siphon_replicated_at) AS modified_paths_size,
                      argMax(commits_count, _siphon_replicated_at) AS commits_count,
                      argMax(first_approved_at, _siphon_replicated_at) AS first_approved_at,
                      argMax(first_reassigned_at, _siphon_replicated_at) AS first_reassigned_at,
                      argMax(added_lines, _siphon_replicated_at) AS added_lines,
                      argMax(removed_lines, _siphon_replicated_at) AS removed_lines,
                      argMax(first_contribution, _siphon_replicated_at) AS first_contribution,
                      argMax(pipeline_id, _siphon_replicated_at) AS pipeline_id,
                      argMax(reviewer_first_assigned_at, _siphon_replicated_at) AS reviewer_first_assigned_at,
                      argMax(_siphon_deleted, _siphon_replicated_at) AS _siphon_deleted
                  FROM siphon_merge_request_metrics
                  GROUP BY
                      merge_request_id,
                      id
              )
              WHERE _siphon_deleted = false
          )
      SELECT
          multiIf(cte.target_project_id != 0, project_namespace_paths.traversal_path, '0/') AS traversal_path,
          cte.id AS id,
          cte.target_branch AS target_branch,
          cte.source_branch AS source_branch,
          cte.source_project_id AS source_project_id,
          cte.author_id AS author_id,
          cte.assignee_id AS assignee_id,
          cte.title AS title,
          cte.created_at AS created_at,
          cte.updated_at AS updated_at,
          cte.milestone_id AS milestone_id,
          cte.merge_status AS merge_status,
          cte.target_project_id AS target_project_id,
          cte.iid AS iid,
          cte.description AS description,
          cte.updated_by_id AS updated_by_id,
          cte.merge_error AS merge_error,
          cte.merge_params AS merge_params,
          cte.merge_when_pipeline_succeeds AS merge_when_pipeline_succeeds,
          cte.merge_user_id AS merge_user_id,
          cte.merge_commit_sha AS merge_commit_sha,
          cte.approvals_before_merge AS approvals_before_merge,
          cte.rebase_commit_sha AS rebase_commit_sha,
          cte.in_progress_merge_commit_sha AS in_progress_merge_commit_sha,
          cte.lock_version AS lock_version,
          cte.time_estimate AS time_estimate,
          cte.squash AS squash,
          cte.cached_markdown_version AS cached_markdown_version,
          cte.last_edited_at AS last_edited_at,
          cte.last_edited_by_id AS last_edited_by_id,
          cte.merge_jid AS merge_jid,
          cte.discussion_locked AS discussion_locked,
          cte.latest_merge_request_diff_id AS latest_merge_request_diff_id,
          cte.allow_maintainer_to_push AS allow_maintainer_to_push,
          cte.state_id AS state_id,
          cte.rebase_jid AS rebase_jid,
          cte.squash_commit_sha AS squash_commit_sha,
          cte.sprint_id AS sprint_id,
          cte.merge_ref_sha AS merge_ref_sha,
          cte.draft AS draft,
          cte.prepared_at AS prepared_at,
          cte.merged_commit_sha AS merged_commit_sha,
          cte.override_requested_changes AS override_requested_changes,
          cte.head_pipeline_id AS head_pipeline_id,
          cte.imported_from AS imported_from,
          cte.retargeted AS retargeted,
          cte._siphon_replicated_at AS version,
          cte._siphon_deleted AS deleted,
          collected_label_ids.label_ids AS label_ids,
          collected_assignee_ids.user_ids AS assignee_ids,
          collected_approver_ids.user_ids AS approver_ids,
          collected_merge_request_metrics.latest_build_started_at AS metric_latest_build_started_at,
          collected_merge_request_metrics.latest_build_finished_at AS metric_latest_build_finished_at,
          collected_merge_request_metrics.first_deployed_to_production_at AS metric_first_deployed_to_production_at,
          collected_merge_request_metrics.merged_at AS metric_merged_at,
          collected_merge_request_metrics.merged_by_id AS metric_merged_by_id,
          collected_merge_request_metrics.latest_closed_by_id AS metric_latest_closed_by_id,
          collected_merge_request_metrics.latest_closed_at AS metric_latest_closed_at,
          collected_merge_request_metrics.first_comment_at AS metric_first_comment_at,
          collected_merge_request_metrics.first_commit_at AS metric_first_commit_at,
          collected_merge_request_metrics.last_commit_at AS metric_last_commit_at,
          collected_merge_request_metrics.diff_size AS metric_diff_size,
          collected_merge_request_metrics.modified_paths_size AS metric_modified_paths_size,
          collected_merge_request_metrics.commits_count AS metric_commits_count,
          collected_merge_request_metrics.first_approved_at AS metric_first_approved_at,
          collected_merge_request_metrics.first_reassigned_at AS metric_first_reassigned_at,
          collected_merge_request_metrics.added_lines AS metric_added_lines,
          collected_merge_request_metrics.removed_lines AS metric_removed_lines,
          collected_merge_request_metrics.first_contribution AS metric_first_contribution,
          collected_merge_request_metrics.pipeline_id AS metric_pipeline_id,
          collected_merge_request_metrics.reviewer_first_assigned_at AS metric_reviewer_first_assigned_at
      FROM cte
      LEFT JOIN project_namespace_paths ON project_namespace_paths.id = cte.target_project_id
      LEFT JOIN collected_assignee_ids ON collected_assignee_ids.merge_request_id = cte.id
      LEFT JOIN collected_label_ids ON collected_label_ids.merge_request_id = cte.id
      LEFT JOIN collected_approver_ids ON collected_approver_ids.merge_request_id = cte.id
      LEFT JOIN collected_merge_request_metrics ON collected_merge_request_metrics.merge_request_id = cte.id;
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW hierarchy_work_items_mv TO hierarchy_work_items
      (
          `traversal_path` String,
          `id` Int64,
          `title` String,
          `author_id` Nullable(Int64),
          `created_at` DateTime64(6, 'UTC'),
          `updated_at` DateTime64(6, 'UTC'),
          `milestone_id` Nullable(Int64),
          `iid` Nullable(Int64),
          `updated_by_id` Nullable(Int64),
          `weight` Nullable(Int64),
          `confidential` Bool,
          `due_date` Nullable(Date32),
          `moved_to_id` Nullable(Int64),
          `time_estimate` Nullable(Int64),
          `relative_position` Nullable(Int64),
          `last_edited_at` Nullable(DateTime64(6, 'UTC')),
          `last_edited_by_id` Nullable(Int64),
          `closed_at` Nullable(DateTime64(6, 'UTC')),
          `closed_by_id` Nullable(Int64),
          `state_id` Int8,
          `duplicated_to_id` Nullable(Int64),
          `promoted_to_epic_id` Nullable(Int64),
          `health_status` Nullable(Int8),
          `sprint_id` Nullable(Int64),
          `blocking_issues_count` Int64,
          `upvotes_count` Int64,
          `work_item_type_id` Int64,
          `namespace_id` Int64,
          `start_date` Nullable(Date32),
          `label_ids` String,
          `assignee_ids` String,
          `custom_status_id` Int64,
          `system_defined_status_id` Int64,
          `version` DateTime64(6, 'UTC'),
          `deleted` Bool
      )
      AS WITH
          cte AS
          (
              SELECT *
              FROM siphon_issues
          ),
          namespace_paths AS
          (
              SELECT *
              FROM
              (
                  SELECT
                      id,
                      argMax(traversal_path, version) AS traversal_path,
                      argMax(deleted, version) AS deleted
                  FROM namespace_traversal_paths
                  WHERE id IN (
                      SELECT DISTINCT namespace_id
                      FROM cte
                  )
                  GROUP BY id
              )
              WHERE deleted = false
          ),
          collected_label_ids AS
          (
              SELECT
                  work_item_id,
                  concat('/', arrayStringConcat(arraySort(groupArray(label_id)), '/'), '/') AS label_ids
              FROM
              (
                  SELECT
                      work_item_id,
                      label_id,
                      id,
                      argMax(deleted, version) AS deleted
                  FROM work_item_label_links
                  WHERE work_item_id IN (
                      SELECT id
                      FROM cte
                  )
                  GROUP BY
                      work_item_id,
                      label_id,
                      id
              )
              WHERE deleted = false
              GROUP BY work_item_id
          ),
          collected_assignee_ids AS
          (
              SELECT
                  issue_id,
                  concat('/', arrayStringConcat(arraySort(groupArray(user_id)), '/'), '/') AS user_ids
              FROM
              (
                  SELECT
                      issue_id,
                      user_id,
                      argMax(_siphon_deleted, _siphon_replicated_at) AS _siphon_deleted
                  FROM siphon_issue_assignees
                  WHERE issue_id IN (
                      SELECT id
                      FROM cte
                  )
                  GROUP BY
                      issue_id,
                      user_id
              )
              WHERE _siphon_deleted = false
              GROUP BY issue_id
          ),
          collected_custom_status_records AS
          (
              SELECT
                  work_item_id,
                  max(system_defined_status_id) AS system_defined_status_id,
                  max(custom_status_id) AS custom_status_id
              FROM
              (
                  SELECT
                      work_item_id,
                      id,
                      argMax(system_defined_status_id, _siphon_replicated_at) AS system_defined_status_id,
                      argMax(custom_status_id, _siphon_replicated_at) AS custom_status_id,
                      argMax(_siphon_deleted, _siphon_replicated_at) AS _siphon_deleted
                  FROM siphon_work_item_current_statuses
                  GROUP BY
                      work_item_id,
                      id
              )
              WHERE _siphon_deleted = false
              GROUP BY work_item_id
          )
      SELECT
          multiIf(cte.namespace_id != 0, namespace_paths.traversal_path, '0/') AS traversal_path,
          cte.id AS id,
          cte.title AS title,
          cte.author_id AS author_id,
          cte.created_at AS created_at,
          cte.updated_at AS updated_at,
          cte.milestone_id AS milestone_id,
          cte.iid AS iid,
          cte.updated_by_id AS updated_by_id,
          cte.weight AS weight,
          cte.confidential AS confidential,
          cte.due_date AS due_date,
          cte.moved_to_id AS moved_to_id,
          cte.time_estimate AS time_estimate,
          cte.relative_position AS relative_position,
          cte.last_edited_at AS last_edited_at,
          cte.last_edited_by_id AS last_edited_by_id,
          cte.closed_at AS closed_at,
          cte.closed_by_id AS closed_by_id,
          cte.state_id AS state_id,
          cte.duplicated_to_id AS duplicated_to_id,
          cte.promoted_to_epic_id AS promoted_to_epic_id,
          cte.health_status AS health_status,
          cte.sprint_id AS sprint_id,
          cte.blocking_issues_count AS blocking_issues_count,
          cte.upvotes_count AS upvotes_count,
          cte.work_item_type_id AS work_item_type_id,
          cte.namespace_id AS namespace_id,
          cte.start_date AS start_date,
          collected_label_ids.label_ids AS label_ids,
          collected_assignee_ids.user_ids AS assignee_ids,
          collected_custom_status_records.custom_status_id AS custom_status_id,
          collected_custom_status_records.system_defined_status_id AS system_defined_status_id,
          cte._siphon_replicated_at AS version,
          cte._siphon_deleted AS deleted
      FROM cte
      LEFT JOIN namespace_paths ON namespace_paths.id = cte.namespace_id
      LEFT JOIN collected_assignee_ids ON collected_assignee_ids.issue_id = cte.id
      LEFT JOIN collected_label_ids ON collected_label_ids.work_item_id = cte.id
      LEFT JOIN collected_custom_status_records ON collected_custom_status_records.work_item_id = cte.id;
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW work_item_award_emoji_mv TO work_item_award_emoji
      (
          `work_item_id` Int64,
          `id` Int64,
          `name` LowCardinality(String),
          `user_id` Int64,
          `created_at` DateTime64(6, 'UTC'),
          `updated_at` DateTime64(6, 'UTC'),
          `version` DateTime64(6, 'UTC'),
          `deleted` Bool
      )
      AS SELECT
          awardable_id AS work_item_id,
          id,
          name,
          user_id,
          created_at,
          updated_at,
          _siphon_replicated_at AS version,
          _siphon_deleted AS deleted
      FROM siphon_award_emoji
      WHERE awardable_type = 'Issue';
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW work_item_award_emoji_trigger_mv TO work_item_award_emoji_trigger
      (
          `work_item_id` Int64
      )
      AS SELECT DISTINCT work_item_id
      FROM work_item_award_emoji;
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW work_item_award_emoji_aggregations_mv TO work_item_award_emoji_aggregations
      (
          `work_item_id` Int64,
          `counts_by_emoji` Map(LowCardinality(String), UInt32),
          `user_ids_by_emoji` Map(LowCardinality(String), String)
      )
      AS WITH
          work_item_ids AS
          (
              SELECT work_item_id
              FROM work_item_award_emoji_trigger
          ),
          aggregation AS
          (
              SELECT
                  work_item_id,
                  mapFromArrays(CAST(groupArray(name), 'Array(LowCardinality(String))'), groupArray(toUInt32(count))) AS counts_by_emoji,
                  mapFromArrays(CAST(groupArray(name), 'Array(LowCardinality(String))'), CAST(groupArray(concat('/', arrayStringConcat(user_ids, '/'), '/')), 'Array(String)')) AS user_ids_by_emoji,
                  false AS deleted,
                  now() AS version
              FROM
              (
                  SELECT
                      work_item_id,
                      name,
                      countDistinct(user_id) AS count,
                      arraySort(groupUniqArray(user_id)) AS user_ids
                  FROM
                  (
                      SELECT
                          work_item_id,
                          id,
                          argMax(name, version) AS name,
                          argMax(user_id, version) AS user_id,
                          argMax(deleted, version) AS deleted
                      FROM work_item_award_emoji
                      WHERE work_item_id IN (
                          SELECT work_item_id
                          FROM work_item_ids
                      )
                      GROUP BY
                          work_item_id,
                          id
                  ) AS work_item_award_emoji
                  WHERE deleted = false
                  GROUP BY
                      work_item_id,
                      name
              )
              GROUP BY work_item_id
          )
      SELECT
          work_item_ids.work_item_id AS work_item_id,
          aggregation.counts_by_emoji AS counts_by_emoji,
          aggregation.user_ids_by_emoji AS user_ids_by_emoji
      FROM work_item_ids
      LEFT JOIN aggregation ON aggregation.work_item_id = work_item_ids.work_item_id;
    SQL
  end
end
