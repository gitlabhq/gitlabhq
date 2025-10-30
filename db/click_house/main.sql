CREATE TABLE ai_usage_events
(
    `user_id` UInt64,
    `event` UInt16,
    `timestamp` DateTime64(6, 'UTC'),
    `namespace_path` String DEFAULT '0/',
    `extras` String DEFAULT '{}'
)
ENGINE = ReplacingMergeTree
PARTITION BY toYYYYMM(timestamp)
ORDER BY (namespace_path, event, timestamp, user_id)
SETTINGS index_granularity = 8192;

CREATE TABLE ci_finished_builds
(
    `id` UInt64 DEFAULT 0,
    `project_id` UInt64 DEFAULT 0,
    `pipeline_id` UInt64 DEFAULT 0,
    `status` LowCardinality(String) DEFAULT '',
    `created_at` DateTime64(6, 'UTC') DEFAULT 0,
    `queued_at` DateTime64(6, 'UTC') DEFAULT 0,
    `finished_at` DateTime64(6, 'UTC') DEFAULT 0,
    `started_at` DateTime64(6, 'UTC') DEFAULT 0,
    `runner_id` UInt64 DEFAULT 0,
    `runner_manager_system_xid` String DEFAULT '',
    `runner_run_untagged` Bool DEFAULT false,
    `runner_type` UInt8 DEFAULT 0,
    `runner_manager_version` LowCardinality(String) DEFAULT '',
    `runner_manager_revision` LowCardinality(String) DEFAULT '',
    `runner_manager_platform` LowCardinality(String) DEFAULT '',
    `runner_manager_architecture` LowCardinality(String) DEFAULT '',
    `duration` Int64 MATERIALIZED if((started_at > 0) AND (finished_at > started_at), age('ms', started_at, finished_at), 0),
    `queueing_duration` Int64 MATERIALIZED if((queued_at > 0) AND (started_at > queued_at), age('ms', queued_at, started_at), 0),
    `root_namespace_id` UInt64 DEFAULT 0,
    `name` String DEFAULT '',
    `date` Date32 MATERIALIZED toStartOfMonth(finished_at),
    `runner_owner_namespace_id` UInt64 DEFAULT 0,
    `stage_id` UInt64 DEFAULT 0,
    PROJECTION build_stats_by_project_pipeline_name_stage
    (
        SELECT
            project_id,
            pipeline_id,
            name,
            stage_id,
            countIf(status = 'success') AS success_count,
            countIf(status = 'failed') AS failed_count,
            countIf(status = 'canceled') AS canceled_count,
            count() AS total_count,
            sum(duration) AS sum_duration,
            avg(duration) AS avg_duration,
            quantile(0.95)(duration) AS p95_duration,
            quantilesTDigest(0.5, 0.75, 0.9, 0.99)(duration) AS duration_quantiles
        GROUP BY
            project_id,
            pipeline_id,
            name,
            stage_id
    )
)
ENGINE = ReplacingMergeTree
PARTITION BY toYear(finished_at)
ORDER BY (status, runner_type, project_id, finished_at, id)
SETTINGS index_granularity = 8192, use_async_block_ids_cache = true, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE ci_finished_builds_aggregated_queueing_delay_percentiles
(
    `status` LowCardinality(String) DEFAULT '',
    `runner_type` UInt8 DEFAULT 0,
    `started_at_bucket` DateTime64(6, 'UTC') DEFAULT now(),
    `count_builds` AggregateFunction(count),
    `queueing_duration_quantile` AggregateFunction(quantile, Int64)
)
ENGINE = AggregatingMergeTree
ORDER BY (started_at_bucket, status, runner_type)
SETTINGS index_granularity = 8192;

CREATE TABLE ci_finished_builds_aggregated_queueing_delay_percentiles_by_owner
(
    `started_at_bucket` DateTime64(6, 'UTC') DEFAULT now(),
    `status` LowCardinality(String) DEFAULT '',
    `runner_type` UInt8 DEFAULT 0,
    `runner_owner_namespace_id` UInt64 DEFAULT 0,
    `count_builds` AggregateFunction(count),
    `queueing_duration_quantile` AggregateFunction(quantile, Int64)
)
ENGINE = AggregatingMergeTree
ORDER BY (started_at_bucket, status, runner_type, runner_owner_namespace_id)
SETTINGS index_granularity = 8192;

CREATE TABLE ci_finished_pipelines
(
    `id` UInt64 DEFAULT 0,
    `path` String DEFAULT '0/',
    `committed_at` DateTime64(6, 'UTC') DEFAULT 0,
    `created_at` DateTime64(6, 'UTC') DEFAULT 0,
    `started_at` DateTime64(6, 'UTC') DEFAULT 0,
    `finished_at` DateTime64(6, 'UTC') DEFAULT 0,
    `duration` UInt64 DEFAULT 0,
    `date` Date32 MATERIALIZED toStartOfMonth(finished_at),
    `status` LowCardinality(String) DEFAULT '',
    `source` LowCardinality(String) DEFAULT '',
    `ref` String DEFAULT '',
    `name` String DEFAULT '',
    PROJECTION by_path_source_ref_finished_at
    (
        SELECT *
        ORDER BY
            path,
            source,
            ref,
            finished_at,
            id
    )
)
ENGINE = ReplacingMergeTree
PARTITION BY toYear(finished_at)
ORDER BY id
SETTINGS index_granularity = 8192, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE ci_finished_pipelines_daily
(
    `path` String DEFAULT '0/',
    `status` LowCardinality(String) DEFAULT '',
    `source` LowCardinality(String) DEFAULT '',
    `ref` String DEFAULT '',
    `started_at_bucket` DateTime64(6, 'UTC') DEFAULT now64(),
    `count_pipelines` AggregateFunction(count),
    `duration_quantile` AggregateFunction(quantile, UInt64),
    `name` String DEFAULT ''
)
ENGINE = AggregatingMergeTree
ORDER BY (started_at_bucket, path, status, source, ref)
SETTINGS index_granularity = 8192;

CREATE TABLE ci_finished_pipelines_hourly
(
    `path` String DEFAULT '0/',
    `status` LowCardinality(String) DEFAULT '',
    `source` LowCardinality(String) DEFAULT '',
    `ref` String DEFAULT '',
    `started_at_bucket` DateTime64(6, 'UTC') DEFAULT now64(),
    `count_pipelines` AggregateFunction(count),
    `duration_quantile` AggregateFunction(quantile, UInt64),
    `name` String DEFAULT ''
)
ENGINE = AggregatingMergeTree
ORDER BY (started_at_bucket, path, status, source, ref)
SETTINGS index_granularity = 8192;

CREATE TABLE ci_used_minutes
(
    `project_id` UInt64 DEFAULT 0,
    `status` LowCardinality(String) DEFAULT '',
    `runner_type` UInt8 DEFAULT 0,
    `finished_at_bucket` DateTime64(6, 'UTC') DEFAULT now64(),
    `count_builds` AggregateFunction(count),
    `total_duration` SimpleAggregateFunction(sum, Int64)
)
ENGINE = AggregatingMergeTree
ORDER BY (finished_at_bucket, project_id, status, runner_type)
SETTINGS index_granularity = 8192;

CREATE TABLE ci_used_minutes_by_runner_daily
(
    `finished_at_bucket` DateTime64(6, 'UTC') DEFAULT now64(),
    `runner_type` UInt8 DEFAULT 0,
    `status` LowCardinality(String) DEFAULT '',
    `runner_id` UInt64 DEFAULT 0,
    `count_builds` AggregateFunction(count),
    `total_duration` SimpleAggregateFunction(sum, Int64),
    `project_id` UInt64 DEFAULT 0
)
ENGINE = AggregatingMergeTree
ORDER BY (finished_at_bucket, runner_type, status, runner_id)
SETTINGS index_granularity = 8192;

CREATE TABLE code_suggestion_events
(
    `user_id` UInt64 DEFAULT 0,
    `event` UInt8 DEFAULT 0,
    `timestamp` DateTime64(6, 'UTC') DEFAULT now64(),
    `namespace_path` String DEFAULT '0/',
    `unique_tracking_id` String DEFAULT '',
    `language` LowCardinality(String) DEFAULT '',
    `suggestion_size` UInt64 DEFAULT 0,
    `branch_name` String DEFAULT ''
)
ENGINE = ReplacingMergeTree
PARTITION BY toYear(timestamp)
ORDER BY (namespace_path, user_id, event, timestamp)
SETTINGS index_granularity = 8192;

CREATE TABLE code_suggestion_events_daily
(
    `namespace_path` String DEFAULT '0/',
    `user_id` UInt64 DEFAULT 0,
    `date` Date32 DEFAULT toDate(now64()),
    `event` UInt8 DEFAULT 0,
    `language` String DEFAULT '',
    `suggestions_size_sum` UInt32 DEFAULT 0,
    `occurrences` UInt64 DEFAULT 0
)
ENGINE = SummingMergeTree
PARTITION BY toYear(date)
ORDER BY (namespace_path, date, user_id, event, language)
SETTINGS index_granularity = 64;

CREATE TABLE contributions
(
    `id` UInt64 DEFAULT 0,
    `path` String DEFAULT '',
    `author_id` UInt64 DEFAULT 0,
    `target_type` LowCardinality(String) DEFAULT '',
    `action` UInt8 DEFAULT 0,
    `created_at` Date DEFAULT toDate(now64()),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now64()
)
ENGINE = ReplacingMergeTree
PARTITION BY toYear(created_at)
ORDER BY (path, created_at, author_id, id)
SETTINGS index_granularity = 8192;

CREATE TABLE contributions_new
(
    `id` UInt64 DEFAULT 0,
    `path` String DEFAULT '',
    `author_id` UInt64 DEFAULT 0,
    `target_type` LowCardinality(String) DEFAULT '',
    `action` UInt8 DEFAULT 0,
    `created_at` Date DEFAULT toDate(now64()),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now64(),
    `version` DateTime64(6, 'UTC') DEFAULT now(),
    `deleted` Bool DEFAULT false
)
ENGINE = ReplacingMergeTree(version, deleted)
PARTITION BY toYear(created_at)
ORDER BY (path, created_at, author_id, id)
SETTINGS index_granularity = 8192;

CREATE TABLE duo_chat_daily_events
(
    `user_id` UInt64 DEFAULT 0,
    `date` Date32 DEFAULT toDate(now64()),
    `event` UInt8 DEFAULT 0,
    `occurrences` UInt64 DEFAULT 0
)
ENGINE = SummingMergeTree
PARTITION BY toYear(date)
ORDER BY (user_id, date, event)
SETTINGS index_granularity = 64;

CREATE TABLE duo_chat_events
(
    `user_id` UInt64 DEFAULT 0,
    `event` UInt8 DEFAULT 0,
    `namespace_path` String DEFAULT '0/',
    `timestamp` DateTime64(6, 'UTC') DEFAULT now64()
)
ENGINE = ReplacingMergeTree
PARTITION BY toYear(timestamp)
ORDER BY (namespace_path, user_id, event, timestamp)
SETTINGS index_granularity = 8192;

CREATE TABLE duo_chat_events_daily
(
    `namespace_path` String DEFAULT '0/',
    `user_id` UInt64 DEFAULT 0,
    `date` Date32 DEFAULT toDate(now64()),
    `event` UInt8 DEFAULT 0,
    `occurrences` UInt64 DEFAULT 0
)
ENGINE = SummingMergeTree
PARTITION BY toYear(date)
ORDER BY (namespace_path, user_id, date, event)
SETTINGS index_granularity = 64;

CREATE TABLE event_authors
(
    `author_id` UInt64 DEFAULT 0,
    `deleted` UInt8 DEFAULT 0,
    `last_event_at` DateTime64(6, 'UTC') DEFAULT now64()
)
ENGINE = ReplacingMergeTree(last_event_at, deleted)
PRIMARY KEY author_id
ORDER BY author_id
SETTINGS index_granularity = 8192;

CREATE TABLE event_namespace_paths
(
    `namespace_id` UInt64 DEFAULT 0,
    `path` String DEFAULT '',
    `deleted` UInt8 DEFAULT 0,
    `last_event_at` DateTime64(6, 'UTC') DEFAULT now64()
)
ENGINE = ReplacingMergeTree(last_event_at, deleted)
PRIMARY KEY namespace_id
ORDER BY namespace_id
SETTINGS index_granularity = 8192;

CREATE TABLE events
(
    `id` UInt64 DEFAULT 0,
    `path` String DEFAULT '0/',
    `author_id` UInt64 DEFAULT 0,
    `target_id` UInt64 DEFAULT 0,
    `target_type` LowCardinality(String) DEFAULT '',
    `action` UInt8 DEFAULT 0,
    `deleted` UInt8 DEFAULT 0,
    `created_at` DateTime64(6, 'UTC') DEFAULT now(),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now()
)
ENGINE = ReplacingMergeTree(updated_at, deleted)
PARTITION BY toYear(created_at)
PRIMARY KEY id
ORDER BY id
SETTINGS index_granularity = 8192;

CREATE TABLE events_new
(
    `id` Int64 DEFAULT 0,
    `path` String DEFAULT '0/',
    `author_id` UInt64 DEFAULT 0,
    `action` UInt8 DEFAULT 0,
    `target_type` LowCardinality(String) DEFAULT '',
    `target_id` UInt64 DEFAULT 0,
    `created_at` DateTime64(6, 'UTC') DEFAULT now(),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now(),
    `version` DateTime64(6, 'UTC') DEFAULT now(),
    `deleted` Bool DEFAULT false
)
ENGINE = ReplacingMergeTree(version, deleted)
PARTITION BY toYear(created_at)
PRIMARY KEY id
ORDER BY id
SETTINGS index_granularity = 8192;

CREATE TABLE hierarchy_audit_events
(
    `traversal_path` String,
    `id` Int64,
    `group_id` Int64,
    `author_id` Int64,
    `target_id` Int64,
    `event_name` String DEFAULT '',
    `details` String DEFAULT '',
    `ip_address` String DEFAULT '',
    `author_name` String DEFAULT '',
    `entity_path` String DEFAULT '',
    `target_details` String DEFAULT '',
    `target_type` String DEFAULT '',
    `created_at` DateTime64(6, 'UTC'),
    `version` DateTime64(6, 'UTC') DEFAULT now(),
    `deleted` Bool DEFAULT false
)
ENGINE = ReplacingMergeTree(version, deleted)
PRIMARY KEY (traversal_path, id)
ORDER BY (traversal_path, id)
SETTINGS index_granularity = 8192;

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

CREATE TABLE hierarchy_work_items
(
    `traversal_path` String,
    `id` Int64,
    `title` String DEFAULT '',
    `author_id` Nullable(Int64),
    `created_at` DateTime64(6, 'UTC') DEFAULT now(),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now(),
    `milestone_id` Nullable(Int64),
    `iid` Nullable(Int64),
    `updated_by_id` Nullable(Int64),
    `weight` Nullable(Int64),
    `confidential` Bool DEFAULT false,
    `due_date` Nullable(Date32),
    `moved_to_id` Nullable(Int64),
    `time_estimate` Nullable(Int64) DEFAULT 0,
    `relative_position` Nullable(Int64),
    `last_edited_at` Nullable(DateTime64(6, 'UTC')),
    `last_edited_by_id` Nullable(Int64),
    `closed_at` Nullable(DateTime64(6, 'UTC')),
    `closed_by_id` Nullable(Int64),
    `state_id` Int8 DEFAULT 1,
    `duplicated_to_id` Nullable(Int64),
    `promoted_to_epic_id` Nullable(Int64),
    `health_status` Nullable(Int8),
    `sprint_id` Nullable(Int64),
    `blocking_issues_count` Int64 DEFAULT 0,
    `upvotes_count` Int64 DEFAULT 0,
    `work_item_type_id` Int64,
    `namespace_id` Int64,
    `start_date` Nullable(Date32),
    `custom_status_id` Int64,
    `system_defined_status_id` Int64,
    `version` DateTime64(6, 'UTC') DEFAULT now(),
    `deleted` Bool DEFAULT false,
    `label_ids` String DEFAULT '',
    `assignee_ids` String DEFAULT ''
)
ENGINE = ReplacingMergeTree(version, deleted)
PRIMARY KEY (traversal_path, work_item_type_id, id)
ORDER BY (traversal_path, work_item_type_id, id)
SETTINGS index_granularity = 8192;

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

CREATE TABLE namespace_traversal_paths
(
    `id` Int64 DEFAULT 0,
    `traversal_path` String DEFAULT '0/',
    `version` DateTime64(6, 'UTC') DEFAULT now(),
    `deleted` Bool DEFAULT false
)
ENGINE = ReplacingMergeTree(version, deleted)
PRIMARY KEY id
ORDER BY id
SETTINGS index_granularity = 512;

CREATE TABLE project_namespace_traversal_paths
(
    `id` Int64 DEFAULT 0,
    `traversal_path` String DEFAULT '0/',
    `version` DateTime64(6, 'UTC') DEFAULT now(),
    `deleted` Bool DEFAULT false
)
ENGINE = ReplacingMergeTree(version, deleted)
PRIMARY KEY id
ORDER BY id
SETTINGS index_granularity = 512;

CREATE TABLE schema_migrations
(
    `version` LowCardinality(String),
    `active` UInt8 DEFAULT 1,
    `applied_at` DateTime64(6, 'UTC') DEFAULT now64()
)
ENGINE = ReplacingMergeTree(applied_at)
PRIMARY KEY version
ORDER BY version
SETTINGS index_granularity = 8192;

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
    `_siphon_deleted` Bool DEFAULT false
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY id
ORDER BY id
SETTINGS index_granularity = 8192;

CREATE TABLE siphon_bulk_import_entities
(
    `id` Int64,
    `bulk_import_id` Int64,
    `parent_id` Nullable(Int64),
    `namespace_id` Nullable(Int64),
    `project_id` Nullable(Int64),
    `source_type` Int8,
    `source_full_path` String,
    `destination_name` String,
    `destination_namespace` String,
    `status` Int8,
    `jid` Nullable(String),
    `created_at` DateTime64(6, 'UTC'),
    `updated_at` DateTime64(6, 'UTC'),
    `source_xid` Nullable(Int64),
    `migrate_projects` Bool DEFAULT true,
    `has_failures` Nullable(Bool) DEFAULT false,
    `migrate_memberships` Bool DEFAULT true,
    `organization_id` Nullable(Int64),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now(),
    `_siphon_deleted` Bool DEFAULT false
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY id
ORDER BY id
SETTINGS index_granularity = 8192;

CREATE TABLE siphon_events
(
    `project_id` Nullable(Int64),
    `author_id` Int64,
    `created_at` DateTime64(6, 'UTC'),
    `updated_at` DateTime64(6, 'UTC'),
    `action` Int8,
    `target_type` LowCardinality(String) DEFAULT '',
    `group_id` Nullable(Int64),
    `fingerprint` Nullable(String),
    `id` Int64,
    `target_id` Nullable(Int64),
    `imported_from` Int8 DEFAULT 0,
    `personal_namespace_id` Nullable(Int64),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now(),
    `_siphon_deleted` Bool DEFAULT false
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY id
ORDER BY id
SETTINGS index_granularity = 8192;

CREATE TABLE siphon_group_audit_events
(
    `id` Int64,
    `created_at` DateTime64(6, 'UTC'),
    `group_id` Int64,
    `author_id` Int64,
    `target_id` Int64,
    `event_name` String DEFAULT '',
    `details` String DEFAULT '',
    `ip_address` String DEFAULT '',
    `author_name` String DEFAULT '',
    `entity_path` String DEFAULT '',
    `target_details` String DEFAULT '',
    `target_type` String DEFAULT '',
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now(),
    `_siphon_deleted` Bool DEFAULT false
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY id
ORDER BY id
SETTINGS index_granularity = 8192;

CREATE TABLE siphon_issue_assignees
(
    `user_id` Int64,
    `issue_id` Int64,
    `namespace_id` Int64,
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now(),
    `_siphon_deleted` Bool DEFAULT false
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (issue_id, user_id)
ORDER BY (issue_id, user_id)
SETTINGS index_granularity = 8192;

CREATE TABLE siphon_issues
(
    `id` Int64,
    `title` String DEFAULT '',
    `author_id` Nullable(Int64),
    `project_id` Nullable(Int64),
    `created_at` DateTime64(6, 'UTC') DEFAULT now(),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now(),
    `description` String DEFAULT '',
    `milestone_id` Nullable(Int64),
    `iid` Nullable(Int64),
    `updated_by_id` Nullable(Int64),
    `weight` Nullable(Int64),
    `confidential` Bool DEFAULT false,
    `due_date` Nullable(Date32),
    `moved_to_id` Nullable(Int64),
    `lock_version` Int64 DEFAULT 0,
    `time_estimate` Nullable(Int64) DEFAULT 0,
    `relative_position` Nullable(Int64),
    `service_desk_reply_to` Nullable(String),
    `cached_markdown_version` Nullable(Int64),
    `last_edited_at` Nullable(DateTime64(6, 'UTC')),
    `last_edited_by_id` Nullable(Int64),
    `discussion_locked` Nullable(Bool),
    `closed_at` Nullable(DateTime64(6, 'UTC')),
    `closed_by_id` Nullable(Int64),
    `state_id` Int8 DEFAULT 1,
    `duplicated_to_id` Nullable(Int64),
    `promoted_to_epic_id` Nullable(Int64),
    `health_status` Nullable(Int8),
    `external_key` Nullable(String),
    `sprint_id` Nullable(Int64),
    `blocking_issues_count` Int64 DEFAULT 0,
    `upvotes_count` Int64 DEFAULT 0,
    `work_item_type_id` Int64,
    `namespace_id` Int64,
    `start_date` Nullable(Date32),
    `tmp_epic_id` Nullable(Int64),
    `imported_from` Int8 DEFAULT 0,
    `author_id_convert_to_bigint` Nullable(Int64),
    `closed_by_id_convert_to_bigint` Nullable(Int64),
    `duplicated_to_id_convert_to_bigint` Nullable(Int64),
    `id_convert_to_bigint` Int64 DEFAULT 0,
    `last_edited_by_id_convert_to_bigint` Nullable(Int64),
    `milestone_id_convert_to_bigint` Nullable(Int64),
    `moved_to_id_convert_to_bigint` Nullable(Int64),
    `project_id_convert_to_bigint` Nullable(Int64),
    `promoted_to_epic_id_convert_to_bigint` Nullable(Int64),
    `updated_by_id_convert_to_bigint` Nullable(Int64),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now(),
    `_siphon_deleted` Bool DEFAULT false,
    `namespace_traversal_ids` Array(Int64) DEFAULT []
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY id
ORDER BY id
SETTINGS index_granularity = 8192;

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

CREATE TABLE siphon_milestones
(
    `id` Int64,
    `title` String,
    `project_id` Nullable(Int64),
    `description` Nullable(String),
    `due_date` Nullable(Date32),
    `created_at` Nullable(DateTime64(6, 'UTC')),
    `updated_at` Nullable(DateTime64(6, 'UTC')),
    `state` LowCardinality(String) DEFAULT '',
    `iid` Nullable(Int64),
    `title_html` Nullable(String),
    `description_html` Nullable(String),
    `start_date` Nullable(Date32),
    `cached_markdown_version` Nullable(Int64),
    `group_id` Nullable(Int64),
    `lock_version` Int64 DEFAULT 0,
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now(),
    `_siphon_deleted` Bool DEFAULT false
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY id
ORDER BY id
SETTINGS index_granularity = 8192;

CREATE TABLE siphon_namespace_details
(
    `namespace_id` Int64,
    `created_at` Nullable(DateTime64(6, 'UTC')),
    `updated_at` Nullable(DateTime64(6, 'UTC')),
    `cached_markdown_version` Nullable(Int64),
    `description` Nullable(String),
    `description_html` Nullable(String),
    `creator_id` Nullable(Int64),
    `deleted_at` Nullable(DateTime64(6, 'UTC')),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now(),
    `_siphon_deleted` Bool DEFAULT false,
    `state_metadata` String DEFAULT '{}'
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY namespace_id
ORDER BY namespace_id
SETTINGS index_granularity = 8192;

CREATE TABLE siphon_namespaces
(
    `id` Int64,
    `name` String,
    `path` String,
    `owner_id` Nullable(Int64),
    `created_at` Nullable(DateTime64(6, 'UTC')),
    `updated_at` Nullable(DateTime64(6, 'UTC')),
    `type` LowCardinality(String) DEFAULT 'User',
    `description` String DEFAULT '',
    `avatar` Nullable(String),
    `membership_lock` Nullable(Bool) DEFAULT false,
    `share_with_group_lock` Nullable(Bool) DEFAULT false,
    `visibility_level` Int64 DEFAULT 20,
    `request_access_enabled` Bool DEFAULT true,
    `ldap_sync_status` LowCardinality(String) DEFAULT 'ready',
    `ldap_sync_error` Nullable(String),
    `ldap_sync_last_update_at` Nullable(DateTime64(6, 'UTC')),
    `ldap_sync_last_successful_update_at` Nullable(DateTime64(6, 'UTC')),
    `ldap_sync_last_sync_at` Nullable(DateTime64(6, 'UTC')),
    `lfs_enabled` Nullable(Bool),
    `parent_id` Nullable(Int64),
    `shared_runners_minutes_limit` Nullable(Int64),
    `repository_size_limit` Nullable(Int64),
    `require_two_factor_authentication` Bool DEFAULT false,
    `two_factor_grace_period` Int64 DEFAULT 48,
    `cached_markdown_version` Nullable(Int64),
    `project_creation_level` Nullable(Int64),
    `runners_token` Nullable(String),
    `file_template_project_id` Nullable(Int64),
    `saml_discovery_token` Nullable(String),
    `runners_token_encrypted` Nullable(String),
    `custom_project_templates_group_id` Nullable(Int64),
    `auto_devops_enabled` Nullable(Bool),
    `extra_shared_runners_minutes_limit` Nullable(Int64),
    `last_ci_minutes_notification_at` Nullable(DateTime64(6, 'UTC')),
    `last_ci_minutes_usage_notification_level` Nullable(Int64),
    `subgroup_creation_level` Nullable(Int64) DEFAULT 1,
    `emails_disabled` Nullable(Bool),
    `max_pages_size` Nullable(Int64),
    `max_artifacts_size` Nullable(Int64),
    `mentions_disabled` Nullable(Bool),
    `default_branch_protection` Nullable(Int8),
    `unlock_membership_to_ldap` Nullable(Bool),
    `max_personal_access_token_lifetime` Nullable(Int64),
    `push_rule_id` Nullable(Int64),
    `shared_runners_enabled` Bool DEFAULT true,
    `allow_descendants_override_disabled_shared_runners` Bool DEFAULT false,
    `traversal_ids` Array(Int64) DEFAULT [],
    `organization_id` Int64,
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now(),
    `_siphon_deleted` Bool DEFAULT false,
    `state` Int8
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY id
ORDER BY id
SETTINGS index_granularity = 8192;

CREATE TABLE siphon_notes
(
    `note` Nullable(String),
    `noteable_type` LowCardinality(String),
    `author_id` Nullable(Int64),
    `created_at` Nullable(DateTime64(6, 'UTC')),
    `updated_at` Nullable(DateTime64(6, 'UTC')),
    `project_id` Nullable(Int64),
    `attachment` Nullable(String) DEFAULT '',
    `line_code` Nullable(String),
    `commit_id` Nullable(String),
    `noteable_id` Nullable(Int64),
    `system` Bool DEFAULT false,
    `st_diff` Nullable(String),
    `updated_by_id` Nullable(Int64),
    `type` LowCardinality(String) DEFAULT '',
    `position` Nullable(String),
    `original_position` Nullable(String),
    `resolved_at` Nullable(DateTime64(6, 'UTC')),
    `resolved_by_id` Nullable(Int64),
    `discussion_id` Nullable(String),
    `note_html` Nullable(String),
    `cached_markdown_version` Nullable(Int64),
    `change_position` Nullable(String),
    `resolved_by_push` Nullable(Bool),
    `review_id` Nullable(Int64),
    `confidential` Nullable(Bool),
    `last_edited_at` Nullable(DateTime64(6, 'UTC')),
    `internal` Bool DEFAULT false,
    `id` Int64,
    `namespace_id` Nullable(Int64),
    `imported_from` Int8 DEFAULT 0,
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now(),
    `_siphon_deleted` Bool DEFAULT false,
    `organization_id` Nullable(Int64)
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY id
ORDER BY id
SETTINGS index_granularity = 8192;

CREATE TABLE siphon_projects
(
    `id` Int64,
    `name` Nullable(String),
    `path` Nullable(String),
    `description` Nullable(String),
    `created_at` Nullable(DateTime64(6, 'UTC')),
    `updated_at` Nullable(DateTime64(6, 'UTC')),
    `creator_id` Nullable(Int64),
    `namespace_id` Int64,
    `last_activity_at` Nullable(DateTime64(6, 'UTC')),
    `import_url` Nullable(String),
    `visibility_level` Int64 DEFAULT 0,
    `archived` Bool DEFAULT false,
    `avatar` Nullable(String),
    `merge_requests_template` Nullable(String),
    `star_count` Int64 DEFAULT 0,
    `merge_requests_rebase_enabled` Nullable(Bool) DEFAULT false,
    `import_type` Nullable(String),
    `import_source` Nullable(String),
    `approvals_before_merge` Int64 DEFAULT 0,
    `reset_approvals_on_push` Nullable(Bool) DEFAULT true,
    `merge_requests_ff_only_enabled` Nullable(Bool) DEFAULT false,
    `issues_template` Nullable(String),
    `mirror` Bool DEFAULT false,
    `mirror_last_update_at` Nullable(DateTime64(6, 'UTC')),
    `mirror_last_successful_update_at` Nullable(DateTime64(6, 'UTC')),
    `mirror_user_id` Nullable(Int64),
    `shared_runners_enabled` Bool DEFAULT true,
    `runners_token` Nullable(String),
    `build_allow_git_fetch` Bool DEFAULT true,
    `build_timeout` Int64 DEFAULT 3600,
    `mirror_trigger_builds` Bool DEFAULT false,
    `pending_delete` Nullable(Bool) DEFAULT false,
    `public_builds` Bool DEFAULT true,
    `last_repository_check_failed` Nullable(Bool),
    `last_repository_check_at` Nullable(DateTime64(6, 'UTC')),
    `only_allow_merge_if_pipeline_succeeds` Bool DEFAULT false,
    `has_external_issue_tracker` Nullable(Bool),
    `repository_storage` String DEFAULT 'default',
    `repository_read_only` Nullable(Bool),
    `request_access_enabled` Bool DEFAULT true,
    `has_external_wiki` Nullable(Bool),
    `ci_config_path` Nullable(String),
    `lfs_enabled` Nullable(Bool),
    `description_html` Nullable(String),
    `only_allow_merge_if_all_discussions_are_resolved` Nullable(Bool),
    `repository_size_limit` Nullable(Int64),
    `printing_merge_request_link_enabled` Bool DEFAULT true,
    `auto_cancel_pending_pipelines` Int64 DEFAULT 1,
    `service_desk_enabled` Nullable(Bool) DEFAULT true,
    `cached_markdown_version` Nullable(Int64),
    `delete_error` Nullable(String),
    `last_repository_updated_at` Nullable(DateTime64(6, 'UTC')),
    `disable_overriding_approvers_per_merge_request` Nullable(Bool),
    `storage_version` Nullable(Int8),
    `resolve_outdated_diff_discussions` Nullable(Bool),
    `remote_mirror_available_overridden` Nullable(Bool),
    `only_mirror_protected_branches` Nullable(Bool),
    `pull_mirror_available_overridden` Nullable(Bool),
    `jobs_cache_index` Nullable(Int64),
    `external_authorization_classification_label` Nullable(String),
    `mirror_overwrites_diverged_branches` Nullable(Bool),
    `pages_https_only` Nullable(Bool) DEFAULT true,
    `external_webhook_token` Nullable(String),
    `packages_enabled` Nullable(Bool),
    `merge_requests_author_approval` Nullable(Bool) DEFAULT false,
    `pool_repository_id` Nullable(Int64),
    `runners_token_encrypted` Nullable(String),
    `bfg_object_map` Nullable(String),
    `detected_repository_languages` Nullable(Bool),
    `merge_requests_disable_committers_approval` Nullable(Bool),
    `require_password_to_approve` Nullable(Bool),
    `emails_disabled` Nullable(Bool),
    `max_pages_size` Nullable(Int64),
    `max_artifacts_size` Nullable(Int64),
    `pull_mirror_branch_prefix` Nullable(String),
    `remove_source_branch_after_merge` Nullable(Bool),
    `marked_for_deletion_at` Nullable(Date32),
    `marked_for_deletion_by_user_id` Nullable(Int64),
    `autoclose_referenced_issues` Nullable(Bool),
    `suggestion_commit_message` Nullable(String),
    `project_namespace_id` Nullable(Int64),
    `hidden` Bool DEFAULT false,
    `organization_id` Nullable(Int64),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now(),
    `_siphon_deleted` Bool DEFAULT false
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY id
ORDER BY id
SETTINGS index_granularity = 8192;

CREATE TABLE siphon_work_item_current_statuses
(
    `id` Int64,
    `namespace_id` Int64,
    `work_item_id` Int64,
    `system_defined_status_id` Int64,
    `custom_status_id` Int64,
    `updated_at` DateTime64(6, 'UTC'),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now(),
    `_siphon_deleted` Bool DEFAULT false
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (work_item_id, id)
ORDER BY (work_item_id, id)
SETTINGS index_granularity = 8192;

CREATE TABLE subscription_user_add_on_assignment_versions
(
    `id` UInt64,
    `organization_id` UInt64,
    `item_id` UInt64,
    `user_id` UInt64,
    `purchase_id` UInt64,
    `namespace_path` String,
    `add_on_name` String,
    `event` String,
    `created_at` DateTime64(6, 'UTC'),
    `version` DateTime64(6, 'UTC') DEFAULT now(),
    `deleted` Bool DEFAULT false
)
ENGINE = ReplacingMergeTree(version, deleted)
ORDER BY (namespace_path, user_id, item_id, event, id)
SETTINGS index_granularity = 8192;

CREATE TABLE sync_cursors
(
    `table_name` LowCardinality(String) DEFAULT '',
    `primary_key_value` UInt64 DEFAULT 0,
    `recorded_at` DateTime64(6, 'UTC') DEFAULT now()
)
ENGINE = ReplacingMergeTree(recorded_at)
PRIMARY KEY table_name
ORDER BY table_name
SETTINGS index_granularity = 8192;

CREATE TABLE troubleshoot_job_events
(
    `user_id` UInt64 DEFAULT 0,
    `timestamp` DateTime64(6, 'UTC') DEFAULT now64(),
    `job_id` UInt64 DEFAULT 0,
    `project_id` UInt64 DEFAULT 0,
    `event` UInt8 DEFAULT 0,
    `namespace_path` String DEFAULT '',
    `pipeline_id` UInt64 DEFAULT 0,
    `merge_request_id` UInt64 DEFAULT 0
)
ENGINE = ReplacingMergeTree
PARTITION BY toYear(timestamp)
ORDER BY (user_id, event, namespace_path, timestamp)
SETTINGS index_granularity = 8192;

CREATE TABLE user_add_on_assignments_history
(
    `assignment_id` UInt64,
    `namespace_path` String DEFAULT '0/',
    `user_id` UInt64,
    `purchase_id` UInt64,
    `add_on_name` String,
    `assigned_at` DateTime64(6, 'UTC'),
    `revoked_at` Nullable(DateTime64(6, 'UTC'))
)
ENGINE = ReplacingMergeTree(assignment_id)
PARTITION BY toYear(assigned_at)
ORDER BY (namespace_path, assigned_at, user_id)
SETTINGS index_granularity = 8192;

CREATE TABLE user_addon_assignments_history
(
    `assignment_id` UInt64,
    `namespace_path` String DEFAULT '0/',
    `user_id` UInt64,
    `purchase_id` UInt64,
    `add_on_name` String,
    `assigned_at` AggregateFunction(min, Nullable(DateTime64(6, 'UTC'))),
    `revoked_at` AggregateFunction(max, Nullable(DateTime64(6, 'UTC')))
)
ENGINE = AggregatingMergeTree
ORDER BY (namespace_path, user_id, assignment_id)
SETTINGS index_granularity = 8192;

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

CREATE MATERIALIZED VIEW ci_finished_builds_aggregated_queueing_delay_percentiles_by_owner_mv TO ci_finished_builds_aggregated_queueing_delay_percentiles_by_owner
(
    `started_at_bucket` DateTime('UTC'),
    `status` LowCardinality(String),
    `runner_type` UInt8,
    `runner_owner_namespace_id` UInt64,
    `count_builds` AggregateFunction(count),
    `queueing_duration_quantile` AggregateFunction(quantile, Int64)
)
AS SELECT
    toStartOfInterval(started_at, toIntervalMinute(5)) AS started_at_bucket,
    status,
    runner_type,
    runner_owner_namespace_id,
    countState(*) AS count_builds,
    quantileState(queueing_duration) AS queueing_duration_quantile
FROM ci_finished_builds
GROUP BY
    started_at_bucket,
    status,
    runner_type,
    runner_owner_namespace_id;

CREATE MATERIALIZED VIEW ci_finished_builds_aggregated_queueing_delay_percentiles_mv TO ci_finished_builds_aggregated_queueing_delay_percentiles
(
    `status` LowCardinality(String),
    `runner_type` UInt8,
    `started_at_bucket` DateTime('UTC'),
    `count_builds` AggregateFunction(count),
    `queueing_duration_quantile` AggregateFunction(quantile, Int64)
)
AS SELECT
    status,
    runner_type,
    toStartOfInterval(started_at, toIntervalMinute(5)) AS started_at_bucket,
    countState(*) AS count_builds,
    quantileState(queueing_duration) AS queueing_duration_quantile
FROM ci_finished_builds
GROUP BY
    status,
    runner_type,
    started_at_bucket;

CREATE MATERIALIZED VIEW ci_finished_pipelines_daily_mv TO ci_finished_pipelines_daily
(
    `path` String,
    `status` LowCardinality(String),
    `source` LowCardinality(String),
    `ref` String,
    `name` String,
    `started_at_bucket` DateTime('UTC'),
    `count_pipelines` AggregateFunction(count),
    `duration_quantile` AggregateFunction(quantile, UInt64)
)
AS SELECT
    path,
    status,
    source,
    ref,
    name,
    toStartOfInterval(started_at, toIntervalDay(1)) AS started_at_bucket,
    countState() AS count_pipelines,
    quantileState(duration) AS duration_quantile
FROM ci_finished_pipelines
GROUP BY
    path,
    status,
    source,
    ref,
    name,
    started_at_bucket;

CREATE MATERIALIZED VIEW ci_finished_pipelines_hourly_mv TO ci_finished_pipelines_hourly
(
    `path` String,
    `status` LowCardinality(String),
    `source` LowCardinality(String),
    `ref` String,
    `name` String,
    `started_at_bucket` DateTime('UTC'),
    `count_pipelines` AggregateFunction(count),
    `duration_quantile` AggregateFunction(quantile, UInt64)
)
AS SELECT
    path,
    status,
    source,
    ref,
    name,
    toStartOfInterval(started_at, toIntervalHour(1)) AS started_at_bucket,
    countState() AS count_pipelines,
    quantileState(duration) AS duration_quantile
FROM ci_finished_pipelines
GROUP BY
    path,
    status,
    source,
    ref,
    name,
    started_at_bucket;

CREATE MATERIALIZED VIEW ci_used_minutes_by_runner_daily_mv TO ci_used_minutes_by_runner_daily
(
    `finished_at_bucket` DateTime('UTC'),
    `runner_type` UInt8,
    `status` LowCardinality(String),
    `runner_id` UInt64,
    `count_builds` AggregateFunction(count),
    `total_duration` SimpleAggregateFunction(sum, Int64),
    `project_id` UInt64
)
AS SELECT
    toStartOfInterval(finished_at, toIntervalDay(1)) AS finished_at_bucket,
    runner_type,
    status,
    runner_id,
    countState() AS count_builds,
    sumSimpleState(duration) AS total_duration,
    project_id
FROM ci_finished_builds
GROUP BY
    finished_at_bucket,
    runner_type,
    project_id,
    status,
    runner_id;

CREATE MATERIALIZED VIEW ci_used_minutes_mv TO ci_used_minutes
(
    `project_id` UInt64,
    `status` LowCardinality(String),
    `runner_type` UInt8,
    `finished_at_bucket` DateTime('UTC'),
    `count_builds` AggregateFunction(count),
    `total_duration` SimpleAggregateFunction(sum, Int64)
)
AS SELECT
    project_id,
    status,
    runner_type,
    toStartOfInterval(finished_at, toIntervalDay(1)) AS finished_at_bucket,
    countState() AS count_builds,
    sumSimpleState(duration) AS total_duration
FROM ci_finished_builds
GROUP BY
    project_id,
    status,
    runner_type,
    finished_at_bucket;

CREATE MATERIALIZED VIEW code_suggestion_events_daily_mv TO code_suggestion_events_daily
(
    `namespace_path` String,
    `user_id` UInt64,
    `date` Date,
    `event` UInt16,
    `language` LowCardinality(String),
    `suggestions_size_sum` UInt64,
    `occurrences` UInt8
)
AS SELECT
    namespace_path,
    user_id,
    toDate(timestamp) AS date,
    event,
    toLowCardinality(JSONExtractString(extras, 'language')) AS language,
    JSONExtractUInt(extras, 'suggestion_size') AS suggestions_size_sum,
    1 AS occurrences
FROM ai_usage_events
WHERE event IN (1, 2, 3, 4, 5);

CREATE MATERIALIZED VIEW contributions_mv TO contributions
(
    `id` UInt64,
    `path` String,
    `author_id` UInt64,
    `target_type` String,
    `action` UInt8,
    `created_at` Date,
    `updated_at` DateTime64(6, 'UTC')
)
AS SELECT
    id,
    argMax(path, events.updated_at) AS path,
    argMax(author_id, events.updated_at) AS author_id,
    argMax(target_type, events.updated_at) AS target_type,
    argMax(action, events.updated_at) AS action,
    argMax(DATE(created_at), events.updated_at) AS created_at,
    max(events.updated_at) AS updated_at
FROM events
WHERE ((events.action IN (5, 6)) AND (events.target_type = '')) OR ((events.action IN (1, 3, 7, 12)) AND (events.target_type IN ('MergeRequest', 'Issue', 'WorkItem')))
GROUP BY id;

CREATE MATERIALIZED VIEW contributions_new_mv TO contributions_new
(
    `id` Int64,
    `path` String,
    `author_id` UInt64,
    `target_type` String,
    `action` UInt8,
    `created_at` Date,
    `updated_at` Date,
    `deleted` Bool,
    `version` DateTime64(6, 'UTC')
)
AS SELECT
    id,
    argMax(path, events_new.version) AS path,
    argMax(author_id, events_new.version) AS author_id,
    argMax(target_type, events_new.version) AS target_type,
    argMax(action, events_new.version) AS action,
    argMax(DATE(created_at), events_new.version) AS created_at,
    argMax(DATE(updated_at), events_new.version) AS updated_at,
    argMax(deleted, events_new.version) AS deleted,
    max(events_new.version) AS version
FROM events_new
WHERE ((events_new.action IN (5, 6)) AND (events_new.target_type = '')) OR ((events_new.action IN (1, 3, 7, 12)) AND (events_new.target_type IN ('MergeRequest', 'Issue', 'WorkItem')))
GROUP BY id;

CREATE MATERIALIZED VIEW duo_chat_events_daily_mv TO duo_chat_events_daily
(
    `namespace_path` String,
    `user_id` UInt64,
    `date` Date,
    `event` UInt16,
    `occurrences` UInt8
)
AS SELECT
    namespace_path,
    user_id,
    toDate(timestamp) AS date,
    event,
    1 AS occurrences
FROM ai_usage_events
WHERE event = 6;

CREATE MATERIALIZED VIEW event_authors_mv TO event_authors
(
    `author_id` UInt64,
    `deleted` UInt8,
    `last_event_at` DateTime64(6, 'UTC')
)
AS SELECT
    author_id,
    argMax(deleted, events.updated_at) AS deleted,
    max(events.updated_at) AS last_event_at
FROM events
GROUP BY author_id;

CREATE MATERIALIZED VIEW event_namespace_paths_mv TO event_namespace_paths
(
    `namespace_id` String,
    `path` String,
    `deleted` UInt8,
    `last_event_at` DateTime64(6, 'UTC')
)
AS SELECT
    splitByChar('/', path)[length(splitByChar('/', path)) - 1] AS namespace_id,
    path,
    argMax(deleted, events.updated_at) AS deleted,
    max(events.updated_at) AS last_event_at
FROM events
GROUP BY
    namespace_id,
    path;

CREATE MATERIALIZED VIEW events_new_mv TO events_new
(
    `id` Int64,
    `path` String,
    `author_id` Int64,
    `action` Int8,
    `target_type` LowCardinality(String),
    `target_id` Nullable(Int64),
    `created_at` DateTime64(6, 'UTC'),
    `updated_at` DateTime64(6, 'UTC'),
    `version` DateTime64(6, 'UTC'),
    `deleted` Bool
)
AS WITH
    cte AS
    (
        SELECT *
        FROM siphon_events
    ),
    group_lookups AS
    (
        SELECT
            id,
            traversal_path
        FROM namespace_traversal_paths
        WHERE id IN (
            SELECT DISTINCT group_id
            FROM cte
        )
    ),
    project_lookups AS
    (
        SELECT
            id,
            traversal_path
        FROM project_namespace_traversal_paths
        WHERE id IN (
            SELECT DISTINCT project_id
            FROM cte
        )
    )
SELECT
    cte.id AS id,
    multiIf(cte.project_id != 0, project_lookups.traversal_path, cte.group_id != 0, group_lookups.traversal_path, '0/') AS path,
    cte.author_id AS author_id,
    cte.action AS action,
    cte.target_type AS target_type,
    cte.target_id AS target_id,
    cte.created_at AS created_at,
    cte.updated_at AS updated_at,
    cte._siphon_replicated_at AS version,
    cte._siphon_deleted AS deleted
FROM cte
LEFT JOIN group_lookups ON group_lookups.id = cte.group_id
LEFT JOIN project_lookups ON project_lookups.id = cte.project_id;

CREATE MATERIALIZED VIEW hierarchy_audit_events_mv TO hierarchy_audit_events
(
    `traversal_path` String,
    `id` Int64,
    `group_id` Int64,
    `author_id` Int64,
    `target_id` Int64,
    `event_name` String,
    `details` String,
    `ip_address` String,
    `author_name` String,
    `entity_path` String,
    `target_details` String,
    `target_type` String,
    `created_at` DateTime64(6, 'UTC'),
    `version` DateTime64(6, 'UTC'),
    `deleted` Bool
)
AS WITH
    cte AS
    (
        SELECT *
        FROM siphon_group_audit_events
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
                SELECT DISTINCT group_id
                FROM cte
            )
            GROUP BY id
        )
        WHERE deleted = false
    )
SELECT
    multiIf(namespace_paths.traversal_path != '', namespace_paths.traversal_path, '0/') AS traversal_path,
    cte.id AS id,
    cte.group_id AS group_id,
    cte.author_id AS author_id,
    cte.target_id AS target_id,
    cte.event_name AS event_name,
    cte.details AS details,
    cte.ip_address AS ip_address,
    cte.author_name AS author_name,
    cte.entity_path AS entity_path,
    cte.target_details AS target_details,
    cte.target_type AS target_type,
    cte.created_at AS created_at,
    cte._siphon_replicated_at AS version,
    cte._siphon_deleted AS deleted
FROM cte
LEFT JOIN namespace_paths ON namespace_paths.id = cte.group_id;

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

CREATE MATERIALIZED VIEW namespace_traversal_paths_mv TO namespace_traversal_paths
(
    `id` Int64,
    `traversal_path` String,
    `version` DateTime64(6, 'UTC'),
    `deleted` Bool
)
AS SELECT
    id,
    if(length(traversal_ids) = 0, concat(toString(ifNull(organization_id, 0)), '/'), concat(toString(ifNull(organization_id, 0)), '/', arrayStringConcat(traversal_ids, '/'), '/')) AS traversal_path,
    _siphon_replicated_at AS version,
    _siphon_deleted AS deleted
FROM siphon_namespaces;

CREATE MATERIALIZED VIEW project_namespace_traversal_paths_mv TO project_namespace_traversal_paths
(
    `id` Int64,
    `traversal_path` String,
    `version` DateTime64(6, 'UTC'),
    `deleted` Bool
)
AS WITH
    cte AS
    (
        SELECT
            id,
            project_namespace_id
        FROM siphon_projects
    ),
    namespaces_cte AS
    (
        SELECT
            traversal_path,
            id,
            version,
            deleted
        FROM namespace_traversal_paths
        WHERE id IN (
            SELECT project_namespace_id
            FROM cte
        )
    )
SELECT
    cte.id,
    namespaces_cte.traversal_path,
    namespaces_cte.version,
    namespaces_cte.deleted
FROM cte
INNER JOIN namespaces_cte ON namespaces_cte.id = cte.project_namespace_id;

CREATE MATERIALIZED VIEW user_addon_assignments_history_mv TO user_addon_assignments_history
(
    `assignment_id` UInt64,
    `namespace_path` String,
    `purchase_id` UInt64,
    `add_on_name` String,
    `user_id` UInt64,
    `assigned_at` AggregateFunction(min, Nullable(DateTime64(6, 'UTC'))),
    `revoked_at` AggregateFunction(max, Nullable(DateTime64(6, 'UTC')))
)
AS SELECT
    item_id AS assignment_id,
    namespace_path,
    purchase_id,
    add_on_name,
    user_id,
    minState(multiIf(event = 'create', created_at, NULL)) AS assigned_at,
    maxState(multiIf(event = 'destroy', created_at, NULL)) AS revoked_at
FROM subscription_user_add_on_assignment_versions
GROUP BY
    item_id,
    namespace_path,
    user_id,
    purchase_id,
    add_on_name;

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

CREATE MATERIALIZED VIEW work_item_award_emoji_trigger_mv TO work_item_award_emoji_trigger
(
    `work_item_id` Int64
)
AS SELECT DISTINCT work_item_id
FROM work_item_award_emoji;

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
WHERE (target_type = 'Issue') AND (target_id IS NOT NULL) AND (label_id IS NOT NULL)