CREATE DICTIONARY namespace_traversal_paths_dict
(
    `id` UInt64,
    `traversal_path` String
)
PRIMARY KEY id
SOURCE(CLICKHOUSE(USER '$DICTIONARY_USER' PASSWORD '$DICTIONARY_PASSWORD' SECURE '$DICTIONARY_SECURE' QUERY '\n        SELECT id, traversal_path FROM (\n          SELECT id, traversal_path\n          FROM (\n            SELECT\n              id,\n              argMax(traversal_path, version) AS traversal_path,\n              argMax(deleted, version) AS deleted\n              FROM $DICTIONARY_DATABASE.namespace_traversal_paths\n            GROUP BY id\n          )\n          WHERE deleted = false\n        )\n      '))
LIFETIME(MIN 60 MAX 300)
LAYOUT(CACHE(SIZE_IN_CELLS 3000000));

CREATE DICTIONARY organization_traversal_paths_dict
(
    `id` UInt64,
    `traversal_path` String
)
PRIMARY KEY id
SOURCE(CLICKHOUSE(USER '$DICTIONARY_USER' PASSWORD '$DICTIONARY_PASSWORD' SECURE '$DICTIONARY_SECURE' QUERY '\n        SELECT id, traversal_path FROM (\n          SELECT id, traversal_path\n          FROM (\n            SELECT\n              id,\n              concat(toString(id), \'/\') AS traversal_path,\n              argMax(_siphon_deleted, _siphon_replicated_at) AS _siphon_deleted\n              FROM siphon_organizations\n            GROUP BY id\n          )\n          WHERE _siphon_deleted = false\n        )\n      '))
LIFETIME(MIN 60 MAX 300)
LAYOUT(CACHE(SIZE_IN_CELLS 100000));

CREATE DICTIONARY project_traversal_paths_dict
(
    `id` UInt64,
    `traversal_path` String
)
PRIMARY KEY id
SOURCE(CLICKHOUSE(USER '$DICTIONARY_USER' PASSWORD '$DICTIONARY_PASSWORD' SECURE '$DICTIONARY_SECURE' QUERY '\n        SELECT id, traversal_path FROM (\n          SELECT id, traversal_path\n          FROM (\n            SELECT\n              id,\n              argMax(traversal_path, version) AS traversal_path,\n              argMax(deleted, version) AS deleted\n              FROM $DICTIONARY_DATABASE.project_namespace_traversal_paths\n            GROUP BY id\n          )\n          WHERE deleted = false\n        )\n      '))
LIFETIME(MIN 60 MAX 300)
LAYOUT(CACHE(SIZE_IN_CELLS 5000000));

CREATE TABLE agent_platform_sessions
(
    `user_id` UInt64,
    `namespace_path` String,
    `project_id` UInt64,
    `session_id` UInt64,
    `flow_type` String,
    `environment` String,
    `session_year` UInt16,
    `created_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8),
    `started_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8),
    `finished_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8),
    `dropped_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8),
    `stopped_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8),
    `resumed_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8)
)
ENGINE = AggregatingMergeTree
PARTITION BY session_year
ORDER BY (namespace_path, user_id, session_id, flow_type)
SETTINGS index_granularity = 8192;

CREATE TABLE ai_audit_events
(
    `id` UUID CODEC(ZSTD(1)),
    `event_name` LowCardinality(String) DEFAULT '',
    `created_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `author_id` UInt64 DEFAULT 0 CODEC(ZSTD(1)),
    `project_id` Nullable(UInt64) CODEC(ZSTD(1)),
    `group_id` Nullable(UInt64) CODEC(ZSTD(1)),
    `ip_address` String DEFAULT '' CODEC(ZSTD(1)),
    `workflow_id` UInt64 DEFAULT 0 CODEC(DoubleDelta, ZSTD(1)),
    `details` String DEFAULT '{}' CODEC(ZSTD(3)),
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), coalesce(group_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', group_id, '0/'), '0/') CODEC(ZSTD(3)),
    PROJECTION by_workflow_id
    (
        SELECT *
        ORDER BY
            workflow_id,
            created_at,
            id
    )
)
ENGINE = ReplacingMergeTree
PARTITION BY toYYYYMM(created_at)
ORDER BY (traversal_path, workflow_id, created_at, id)
SETTINGS deduplicate_merge_projection_mode = 'rebuild', index_granularity = 8192;

CREATE TABLE ai_code_suggestions
(
    `uid` String,
    `namespace_path` String,
    `user_id` UInt64,
    `timestamp` DateTime64(6, 'UTC'),
    `shown_at` AggregateFunction(minIf, Nullable(DateTime64(6, 'UTC')), UInt8),
    `accepted_at` AggregateFunction(maxIf, Nullable(DateTime64(6, 'UTC')), UInt8),
    `rejected_at` AggregateFunction(maxIf, Nullable(DateTime64(6, 'UTC')), UInt8),
    `language` String,
    `branch_name` String,
    `ide_name` String,
    `ide_vendor` String,
    `ide_version` String,
    `extension_name` String,
    `extension_version` String,
    `language_server_version` String,
    `model_name` String,
    `model_engine` String,
    `suggestion_size` SimpleAggregateFunction(max, UInt64),
    INDEX idx_ai_code_suggestions_timestamp timestamp TYPE minmax GRANULARITY 1
)
ENGINE = AggregatingMergeTree
PARTITION BY toYYYYMM(timestamp)
ORDER BY (namespace_path, user_id, uid)
SETTINGS index_granularity = 8192;

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

CREATE TABLE ai_usage_events_daily
(
    `namespace_path` String DEFAULT '0/',
    `date` Date32 DEFAULT toDate(now64()),
    `event` UInt16 DEFAULT 0,
    `user_id` UInt64 DEFAULT 0,
    `occurrences` UInt64 DEFAULT 0
)
ENGINE = SummingMergeTree
PARTITION BY toYear(date)
ORDER BY (namespace_path, date, event, user_id)
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
    `stage_name` String DEFAULT '',
    `version` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `deleted` Bool DEFAULT false,
    `group_name` String DEFAULT '',
    `namespace_path` String DEFAULT '0/',
    `failure_reason` LowCardinality(String) DEFAULT '',
    `when` LowCardinality(String) DEFAULT '',
    `manual` Bool DEFAULT false,
    `allow_failure` Bool DEFAULT false,
    `user_id` UInt64 DEFAULT 0,
    `artifacts_filename` String DEFAULT '',
    `artifacts_size` UInt64 DEFAULT 0,
    `retries_count` UInt16 DEFAULT 0,
    `runner_tags` Array(String) DEFAULT [],
    `job_definition_id` UInt64 DEFAULT 0,
    PROJECTION by_project_pipeline_finished_at_name_v2
    (
        SELECT
            id,
            project_id,
            pipeline_id,
            status,
            created_at,
            finished_at,
            started_at,
            name,
            stage_name,
            version,
            deleted,
            group_name,
            namespace_path,
            duration,
            queueing_duration
        ORDER BY
            project_id,
            pipeline_id,
            finished_at,
            name,
            id,
            version
    ),
    PROJECTION build_stats_by_project_pipeline_finished_at_name_stage_name
    (
        SELECT
            project_id,
            pipeline_id,
            finished_at,
            name,
            stage_name,
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
            finished_at,
            name,
            stage_name
    )
)
ENGINE = ReplacingMergeTree(version, deleted)
PARTITION BY toYear(finished_at)
ORDER BY (status, runner_type, project_id, finished_at, id)
SETTINGS index_granularity = 8192, use_async_block_ids_cache = true, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE ci_finished_builds_aggregated_queueing_delay_percentiles
(
    `status` LowCardinality(String) DEFAULT '',
    `runner_type` UInt8 DEFAULT 0,
    `started_at_bucket` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `count_builds` AggregateFunction(count),
    `queueing_duration_quantile` AggregateFunction(quantile, Int64)
)
ENGINE = AggregatingMergeTree
ORDER BY (started_at_bucket, status, runner_type)
SETTINGS index_granularity = 8192;

CREATE TABLE ci_finished_builds_aggregated_queueing_delay_percentiles_by_owner
(
    `started_at_bucket` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
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
    `is_default_branch` Bool DEFAULT false,
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
    `started_at_bucket` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
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
    `started_at_bucket` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
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
    `finished_at_bucket` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `count_builds` AggregateFunction(count),
    `total_duration` SimpleAggregateFunction(sum, Int64)
)
ENGINE = AggregatingMergeTree
ORDER BY (finished_at_bucket, project_id, status, runner_type)
SETTINGS index_granularity = 8192;

CREATE TABLE ci_used_minutes_by_runner_daily
(
    `finished_at_bucket` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
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
    `timestamp` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
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

CREATE TABLE code_suggestion_events_daily_new
(
    `namespace_path` String DEFAULT '0/',
    `user_id` UInt64 DEFAULT 0,
    `date` Date32 DEFAULT toDate(now64()),
    `event` UInt8 DEFAULT 0,
    `ide_name` LowCardinality(String) DEFAULT '',
    `language` LowCardinality(String) DEFAULT '',
    `suggestions_size_sum` UInt32 DEFAULT 0,
    `occurrences` UInt64 DEFAULT 0
)
ENGINE = SummingMergeTree
PARTITION BY toYear(date)
ORDER BY (namespace_path, date, user_id, event, ide_name, language)
SETTINGS index_granularity = 64;

CREATE TABLE contributions
(
    `id` UInt64 DEFAULT 0,
    `path` String DEFAULT '',
    `author_id` UInt64 DEFAULT 0,
    `target_type` LowCardinality(String) DEFAULT '',
    `action` UInt8 DEFAULT 0,
    `created_at` Date DEFAULT toDate(now64()),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC')
)
ENGINE = ReplacingMergeTree
PARTITION BY toYear(created_at)
ORDER BY (path, created_at, author_id, id)
SETTINGS index_granularity = 8192;

CREATE TABLE contributions_new
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `path` String CODEC(ZSTD(3)),
    `author_id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `target_type` LowCardinality(String) DEFAULT '',
    `action` Int16 DEFAULT 0,
    `created_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `version` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `deleted` Bool DEFAULT false CODEC(ZSTD(1))
)
ENGINE = ReplacingMergeTree(version, deleted)
PARTITION BY toYear(created_at)
ORDER BY (path, created_at, author_id, id)
SETTINGS index_granularity = 8192;

CREATE TABLE duo_chat_events
(
    `user_id` UInt64 DEFAULT 0,
    `event` UInt8 DEFAULT 0,
    `namespace_path` String DEFAULT '0/',
    `timestamp` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC')
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

CREATE TABLE duo_workflow_session_enrichments
(
    `workflow_id` UInt64 CODEC(DoubleDelta, ZSTD(1)),
    `credits_used` Float64 DEFAULT 0 CODEC(ZSTD(1)),
    `model_used` LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1))
)
ENGINE = ReplacingMergeTree(updated_at)
ORDER BY workflow_id
SETTINGS index_granularity = 8192;

CREATE TABLE event_authors
(
    `author_id` UInt64 DEFAULT 0,
    `deleted` UInt8 DEFAULT 0,
    `last_event_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC')
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
    `last_event_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC')
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
    `created_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC')
)
ENGINE = ReplacingMergeTree(updated_at, deleted)
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
    `version` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
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
    `created_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
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
    `version` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `deleted` Bool DEFAULT false,
    `label_ids` String DEFAULT '',
    `assignee_ids` String DEFAULT ''
)
ENGINE = ReplacingMergeTree(version, deleted)
PRIMARY KEY (traversal_path, work_item_type_id, id)
ORDER BY (traversal_path, work_item_type_id, id)
SETTINGS index_granularity = 8192;

CREATE TABLE merge_requests
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `target_branch` String,
    `source_branch` String,
    `source_project_id` Nullable(Int64),
    `author_id` Nullable(Int64),
    `assignee_id` Nullable(Int64),
    `title` String CODEC(ZSTD(1)),
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `milestone_id` Nullable(Int64),
    `merge_status` LowCardinality(String) DEFAULT 'unchecked',
    `target_project_id` Int64,
    `iid` Int64,
    `description` String CODEC(ZSTD(3)),
    `updated_by_id` Nullable(Int64),
    `merge_error` Nullable(String),
    `merge_params` Nullable(String),
    `merge_when_pipeline_succeeds` Bool DEFAULT false CODEC(ZSTD(1)),
    `merge_user_id` Nullable(Int64),
    `merge_commit_sha` Nullable(String),
    `approvals_before_merge` Nullable(Int64),
    `rebase_commit_sha` Nullable(String),
    `in_progress_merge_commit_sha` Nullable(String),
    `time_estimate` Nullable(Int64) DEFAULT 0,
    `squash` Bool DEFAULT false CODEC(ZSTD(1)),
    `cached_markdown_version` Nullable(Int64),
    `last_edited_at` Nullable(DateTime64(6, 'UTC')),
    `last_edited_by_id` Nullable(Int64),
    `merge_jid` String,
    `discussion_locked` Nullable(Bool) CODEC(ZSTD(1)),
    `latest_merge_request_diff_id` Nullable(Int64),
    `allow_maintainer_to_push` Nullable(Bool) DEFAULT true CODEC(ZSTD(1)),
    `state_id` Int16 DEFAULT 1,
    `rebase_jid` Nullable(String),
    `squash_commit_sha` Nullable(String),
    `merge_ref_sha` Nullable(String),
    `draft` Bool DEFAULT false CODEC(ZSTD(1)),
    `prepared_at` Nullable(DateTime64(6, 'UTC')),
    `merged_commit_sha` Nullable(String),
    `override_requested_changes` Bool DEFAULT false CODEC(ZSTD(1)),
    `head_pipeline_id` Nullable(Int64),
    `imported_from` Int16 DEFAULT 0,
    `retargeted` Bool DEFAULT false CODEC(ZSTD(1)),
    `traversal_path` String DEFAULT multiIf(coalesce(target_project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', target_project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
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
    `reviewers` Array(Tuple(
        user_id UInt64,
        state Int16,
        created_at DateTime64(6, 'UTC'))),
    `assignees` Array(Tuple(
        user_id UInt64,
        created_at DateTime64(6, 'UTC'))),
    `approvals` Array(Tuple(
        user_id UInt64,
        created_at DateTime64(6, 'UTC'))),
    `label_ids` Array(Tuple(
        label_id UInt64,
        created_at DateTime64(6, 'UTC'))),
    `award_emojis` Array(Tuple(
        name String,
        user_id UInt64,
        created_at DateTime64(6, 'UTC'))),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, id)
ORDER BY (traversal_path, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE namespace_traversal_paths
(
    `id` Int64 DEFAULT 0,
    `traversal_path` String DEFAULT '0/',
    `version` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `deleted` Bool DEFAULT false,
    PROJECTION by_traversal_path
    (
        SELECT *
        ORDER BY traversal_path
    )
)
ENGINE = ReplacingMergeTree(version, deleted)
PRIMARY KEY id
ORDER BY id
SETTINGS index_granularity = 512, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE project_namespace_traversal_paths
(
    `id` Int64 DEFAULT 0,
    `traversal_path` String DEFAULT '0/',
    `version` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `deleted` Bool DEFAULT false,
    PROJECTION by_traversal_path
    (
        SELECT *
        ORDER BY traversal_path
    )
)
ENGINE = ReplacingMergeTree(version, deleted)
PRIMARY KEY id
ORDER BY id
SETTINGS index_granularity = 512, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE schema_migrations
(
    `version` LowCardinality(String),
    `active` UInt8 DEFAULT 1,
    `applied_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC')
)
ENGINE = ReplacingMergeTree(applied_at)
PRIMARY KEY version
ORDER BY version
SETTINGS index_granularity = 8192;

CREATE TABLE siphon_approvals
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `merge_request_id` Int64 CODEC(ZSTD(1)),
    `user_id` Int64,
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `patch_id_sha` Nullable(String),
    `project_id` Int64,
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, merge_request_id, id)
ORDER BY (traversal_path, merge_request_id, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_award_emoji
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `name` LowCardinality(String) CODEC(LZ4),
    `user_id` Int64,
    `awardable_type` LowCardinality(String) CODEC(LZ4),
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `awardable_id` Int64 CODEC(ZSTD(1)),
    `namespace_id` Nullable(Int64),
    `organization_id` Nullable(Int64),
    `traversal_path` String DEFAULT multiIf(coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), coalesce(organization_id, 0) != 0, dictGetOrDefault('organization_traversal_paths_dict', 'traversal_path', organization_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, awardable_type, awardable_id, id)
ORDER BY (traversal_path, awardable_type, awardable_id, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

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
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `_siphon_deleted` Bool DEFAULT false,
    `source_xid_convert_to_bigint` Nullable(Int64)
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY id
ORDER BY id
SETTINGS index_granularity = 8192;

CREATE TABLE siphon_ci_runner_namespaces
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `runner_id` Int64,
    `namespace_id` Int64,
    `traversal_path` String DEFAULT multiIf(coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, id)
ORDER BY (traversal_path, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_ci_runner_projects
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `runner_id` Int64,
    `created_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `project_id` Int64,
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, id)
ORDER BY (traversal_path, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_ci_runners
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `creator_id` Nullable(Int64),
    `created_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `contacted_at` Nullable(DateTime64(6, 'UTC')),
    `token_expires_at` Nullable(DateTime64(6, 'UTC')),
    `public_projects_minutes_cost_factor` Float64 DEFAULT 1.,
    `private_projects_minutes_cost_factor` Float64 DEFAULT 1.,
    `access_level` Int64 DEFAULT 0,
    `maximum_timeout` Nullable(Int64),
    `runner_type` Int16 CODEC(DoubleDelta, ZSTD(1)),
    `registration_type` Int16 DEFAULT 0,
    `creation_state` Int16 DEFAULT 0,
    `active` Bool DEFAULT true CODEC(ZSTD(1)),
    `run_untagged` Bool DEFAULT true CODEC(ZSTD(1)),
    `locked` Bool DEFAULT false CODEC(ZSTD(1)),
    `name` Nullable(String),
    `token_encrypted` String DEFAULT '',
    `description` String DEFAULT '' CODEC(ZSTD(3)),
    `maintainer_note` String DEFAULT '' CODEC(ZSTD(3)),
    `allowed_plans` Array(String) DEFAULT [],
    `allowed_plan_ids` Array(Int64) DEFAULT [],
    `organization_id` Nullable(Int64),
    `allowed_plan_name_uids` Array(Int16) DEFAULT [],
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    `token_rotation_deadline` DateTime64(6, 'UTC') DEFAULT toDateTime64('9999-12-31 23:59:59.999999', 6, 'UTC')
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (id, runner_type)
ORDER BY (id, runner_type)
SETTINGS index_granularity = 2048;

CREATE TABLE siphon_deployment_merge_requests
(
    `deployment_id` Int64,
    `merge_request_id` Int64,
    `environment_id` Nullable(Int64),
    `project_id` Int64,
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/'),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `_siphon_deleted` Bool DEFAULT false,
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY
            deployment_id,
            merge_request_id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, deployment_id, merge_request_id)
ORDER BY (traversal_path, deployment_id, merge_request_id)
SETTINGS deduplicate_merge_projection_mode = 'rebuild', index_granularity = 2048;

CREATE TABLE siphon_deployments
(
    `id` Int64,
    `iid` Int64,
    `project_id` Int64,
    `environment_id` Int64,
    `ref` String,
    `tag` Bool,
    `sha` String,
    `user_id` Nullable(Int64),
    `deployable_type` String DEFAULT '',
    `created_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `on_stop` Nullable(String),
    `status` Int8,
    `finished_at` Nullable(DateTime64(6, 'UTC')),
    `deployable_id` Nullable(Int64),
    `archived` Bool DEFAULT false,
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/'),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `_siphon_deleted` Bool DEFAULT false,
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, id)
ORDER BY (traversal_path, id)
SETTINGS deduplicate_merge_projection_mode = 'rebuild', index_granularity = 2048;

CREATE TABLE siphon_duo_workflows_workflows
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `user_id` Int64,
    `project_id` Nullable(Int64),
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `status` Int16 DEFAULT 0,
    `goal` Nullable(String),
    `agent_privileges` Array(Int16) DEFAULT [],
    `workflow_definition` String DEFAULT 'software_development',
    `allow_agent_to_request_user` Bool DEFAULT true,
    `pre_approved_agent_privileges` Array(Int16) DEFAULT [],
    `image` Nullable(String),
    `environment` Nullable(Int16),
    `namespace_id` Nullable(Int64),
    `ai_catalog_item_version_id` Nullable(Int64),
    `issue_id` Nullable(Int64),
    `merge_request_id` Nullable(Int64),
    `service_account_id` Nullable(Int64),
    `tool_call_approvals` String DEFAULT '{}',
    `ai_catalog_item_id` Nullable(Int64),
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, created_at, id)
ORDER BY (traversal_path, created_at, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_environments
(
    `id` Int64,
    `project_id` Int64,
    `name` String,
    `created_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `external_url` Nullable(String),
    `environment_type` Nullable(String),
    `state` String DEFAULT 'available',
    `slug` String,
    `auto_stop_at` Nullable(DateTime64(6, 'UTC')),
    `auto_delete_at` Nullable(DateTime64(6, 'UTC')),
    `tier` Nullable(Int8),
    `merge_request_id` Nullable(Int64),
    `cluster_agent_id` Nullable(Int64),
    `kubernetes_namespace` Nullable(String),
    `flux_resource_path` Nullable(String),
    `description` Nullable(String),
    `description_html` Nullable(String),
    `cached_markdown_version` Nullable(Int64),
    `auto_stop_setting` Int8 DEFAULT 0,
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/'),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `_siphon_deleted` Bool DEFAULT false,
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, id)
ORDER BY (traversal_path, id)
SETTINGS deduplicate_merge_projection_mode = 'rebuild', index_granularity = 2048;

CREATE TABLE siphon_events
(
    `project_id` Nullable(Int64),
    `author_id` Int64,
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `action` Int16,
    `target_type` LowCardinality(String) DEFAULT '',
    `group_id` Nullable(Int64),
    `fingerprint` Nullable(String),
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `target_id` Nullable(Int64),
    `imported_from` Int16 DEFAULT 0,
    `personal_namespace_id` Nullable(Int64),
    `path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), coalesce(group_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', group_id, '0/'), coalesce(personal_namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', personal_namespace_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PARTITION BY toYear(created_at)
PRIMARY KEY (path, id)
ORDER BY (path, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

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
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `_siphon_deleted` Bool DEFAULT false
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY id
ORDER BY id
SETTINGS index_granularity = 8192;

CREATE TABLE siphon_issue_assignees
(
    `user_id` Int64 CODEC(Delta(8), ZSTD(1)),
    `issue_id` Int64 CODEC(Delta(8), ZSTD(1)),
    `namespace_id` Int64,
    `traversal_path` String DEFAULT multiIf(coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY
            issue_id,
            user_id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, issue_id, user_id)
ORDER BY (traversal_path, issue_id, user_id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_issue_links
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `source_id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `target_id` Int64,
    `created_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `link_type` Int8 DEFAULT 0,
    `namespace_id` Int64,
    `traversal_path` String DEFAULT multiIf(coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, source_id, id)
ORDER BY (traversal_path, source_id, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_issue_metrics
(
    `id` Int64 CODEC(Delta(8), ZSTD(1)),
    `issue_id` Int64 CODEC(ZSTD(1)),
    `first_mentioned_in_commit_at` Nullable(DateTime64(6, 'UTC')),
    `first_associated_with_milestone_at` Nullable(DateTime64(6, 'UTC')),
    `first_added_to_board_at` Nullable(DateTime64(6, 'UTC')),
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `namespace_id` Int64,
    `traversal_path` String DEFAULT multiIf(coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, issue_id, id)
ORDER BY (traversal_path, issue_id, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_issues
(
    `id` Int64,
    `title` String,
    `author_id` Nullable(Int64),
    `project_id` Nullable(Int64),
    `created_at` DateTime64(6, 'UTC'),
    `updated_at` DateTime64(6, 'UTC'),
    `description` String,
    `milestone_id` Nullable(Int64),
    `iid` Int64,
    `updated_by_id` Nullable(Int64),
    `weight` Nullable(Int64),
    `confidential` Bool DEFAULT false,
    `due_date` Nullable(Date32),
    `moved_to_id` Nullable(Int64),
    `time_estimate` Nullable(Int64) DEFAULT 0,
    `relative_position` Nullable(Int64),
    `service_desk_reply_to` Nullable(String),
    `cached_markdown_version` Nullable(Int64),
    `last_edited_at` Nullable(DateTime64(6, 'UTC')),
    `last_edited_by_id` Nullable(Int64),
    `discussion_locked` Nullable(Bool),
    `closed_at` Nullable(DateTime64(6, 'UTC')),
    `closed_by_id` Nullable(Int64),
    `state_id` Int16 DEFAULT 1,
    `duplicated_to_id` Nullable(Int64),
    `promoted_to_epic_id` Nullable(Int64),
    `health_status` Nullable(Int16),
    `sprint_id` Nullable(Int64),
    `blocking_issues_count` Int64 DEFAULT 0,
    `upvotes_count` Int64 DEFAULT 0,
    `work_item_type_id` Int64,
    `namespace_id` Int64,
    `start_date` Nullable(Date32),
    `imported_from` Int16 DEFAULT 0,
    `namespace_traversal_ids` Array(Int64) DEFAULT [],
    `traversal_path` String DEFAULT multiIf(coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), '0/'),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `_siphon_deleted` Bool DEFAULT false
)
ENGINE = `Null`;

CREATE TABLE siphon_knowledge_graph_enabled_namespaces
(
    `id` Int64,
    `root_namespace_id` Int64,
    `created_at` DateTime64(6, 'UTC'),
    `updated_at` DateTime64(6, 'UTC'),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `_siphon_deleted` Bool DEFAULT false
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (root_namespace_id, id)
ORDER BY (root_namespace_id, id)
SETTINGS index_granularity = 2048;

CREATE TABLE siphon_label_links
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `label_id` Int64,
    `target_id` Int64 CODEC(ZSTD(1)),
    `target_type` LowCardinality(String) CODEC(LZ4),
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `namespace_id` Int64,
    `traversal_path` String DEFAULT multiIf(coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, target_type, target_id, id)
ORDER BY (traversal_path, target_type, target_id, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_labels
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `title` String CODEC(ZSTD(3)),
    `color` String,
    `project_id` Nullable(Int64),
    `created_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `template` Nullable(Bool) DEFAULT false CODEC(ZSTD(1)),
    `description` String CODEC(ZSTD(3)),
    `type` LowCardinality(String),
    `group_id` Nullable(Int64),
    `lock_on_merge` Bool DEFAULT false CODEC(ZSTD(1)),
    `archived` Bool DEFAULT false CODEC(ZSTD(1)),
    `organization_id` Nullable(Int64),
    `traversal_path` String DEFAULT multiIf(coalesce(group_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', group_id, '0/'), coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), coalesce(organization_id, 0) != 0, dictGetOrDefault('organization_traversal_paths_dict', 'traversal_path', organization_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, id)
ORDER BY (traversal_path, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_members
(
    `id` Int64,
    `access_level` Int64,
    `source_id` Int64,
    `source_type` String,
    `user_id` Nullable(Int64),
    `notification_level` Int64,
    `type` String,
    `created_at` DateTime64(6, 'UTC'),
    `updated_at` DateTime64(6, 'UTC'),
    `created_by_id` Nullable(Int64),
    `invite_email` Nullable(String),
    `invite_token` Nullable(String),
    `invite_accepted_at` Nullable(DateTime64(6, 'UTC')),
    `requested_at` Nullable(DateTime64(6, 'UTC')),
    `expires_at` Nullable(Date32),
    `ldap` Bool DEFAULT false,
    `override` Bool DEFAULT false,
    `state` Int8 DEFAULT 0,
    `invite_email_success` Bool DEFAULT true,
    `member_namespace_id` Nullable(Int64),
    `member_role_id` Nullable(Int64),
    `expiry_notified_at` Nullable(DateTime64(6, 'UTC')),
    `request_accepted_at` Nullable(DateTime64(6, 'UTC')),
    `traversal_path` String DEFAULT multiIf(coalesce(member_namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', member_namespace_id, '0/'), '0/'),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `_siphon_deleted` Bool DEFAULT false,
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, id)
ORDER BY (traversal_path, id)
SETTINGS deduplicate_merge_projection_mode = 'rebuild', index_granularity = 2048;

CREATE TABLE siphon_merge_request_assignees
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `user_id` Int64,
    `merge_request_id` Int64 CODEC(ZSTD(1)),
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `project_id` Int64,
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, merge_request_id, id)
ORDER BY (traversal_path, merge_request_id, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_merge_request_diff_files
(
    `merge_request_diff_id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `relative_order` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `new_file` Bool CODEC(ZSTD(1)),
    `renamed_file` Bool CODEC(ZSTD(1)),
    `deleted_file` Bool CODEC(ZSTD(1)),
    `too_large` Bool CODEC(ZSTD(1)),
    `a_mode` String,
    `b_mode` String,
    `new_path` Nullable(String),
    `old_path` String,
    `diff` Nullable(String),
    `binary` Nullable(Bool) CODEC(ZSTD(1)),
    `external_diff_offset` Nullable(Int64),
    `external_diff_size` Nullable(Int64),
    `generated` Nullable(Bool) CODEC(ZSTD(1)),
    `encoded_file_path` Bool DEFAULT false CODEC(ZSTD(1)),
    `project_id` Nullable(Int64),
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY
            merge_request_diff_id,
            relative_order
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, merge_request_diff_id, relative_order)
ORDER BY (traversal_path, merge_request_diff_id, relative_order)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_merge_request_diffs
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `state` LowCardinality(Nullable(String)),
    `merge_request_id` Int64,
    `created_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `base_commit_sha` Nullable(String),
    `real_size` Nullable(String),
    `head_commit_sha` Nullable(String),
    `start_commit_sha` Nullable(String),
    `commits_count` Nullable(Int64),
    `external_diff` Nullable(String),
    `external_diff_store` Nullable(Int64) DEFAULT 1,
    `stored_externally` Bool DEFAULT false CODEC(ZSTD(1)),
    `files_count` Nullable(Int16),
    `sorted` Bool DEFAULT false CODEC(ZSTD(1)),
    `diff_type` Int8 DEFAULT 1,
    `patch_id_sha` Nullable(String),
    `project_id` Int64,
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, merge_request_id, id)
ORDER BY (traversal_path, merge_request_id, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_merge_request_metrics
(
    `merge_request_id` Int64 CODEC(ZSTD(1)),
    `latest_build_started_at` Nullable(DateTime64(6, 'UTC')),
    `latest_build_finished_at` Nullable(DateTime64(6, 'UTC')),
    `first_deployed_to_production_at` Nullable(DateTime64(6, 'UTC')),
    `merged_at` Nullable(DateTime64(6, 'UTC')),
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
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
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `first_contribution` Bool DEFAULT false CODEC(ZSTD(1)),
    `pipeline_id` Nullable(Int64),
    `reviewer_first_assigned_at` Nullable(DateTime64(6, 'UTC')),
    `traversal_path` String DEFAULT multiIf(coalesce(target_project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', target_project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, merge_request_id, id)
ORDER BY (traversal_path, merge_request_id, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_merge_request_reviewers
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `user_id` Int64,
    `merge_request_id` Int64 CODEC(ZSTD(1)),
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `state` Int16 DEFAULT 0,
    `project_id` Nullable(Int64),
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, merge_request_id, id)
ORDER BY (traversal_path, merge_request_id, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_merge_requests
(
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
    `merge_status` LowCardinality(String) DEFAULT 'unchecked',
    `target_project_id` Int64,
    `iid` Int64,
    `description` String,
    `updated_by_id` Nullable(Int64),
    `merge_error` Nullable(String),
    `merge_params` Nullable(String),
    `merge_when_pipeline_succeeds` Bool DEFAULT false,
    `merge_user_id` Nullable(Int64),
    `merge_commit_sha` Nullable(String),
    `approvals_before_merge` Nullable(Int64),
    `rebase_commit_sha` Nullable(String),
    `in_progress_merge_commit_sha` Nullable(String),
    `time_estimate` Nullable(Int64) DEFAULT 0,
    `squash` Bool DEFAULT false,
    `cached_markdown_version` Nullable(Int64),
    `last_edited_at` Nullable(DateTime64(6, 'UTC')),
    `last_edited_by_id` Nullable(Int64),
    `merge_jid` String,
    `discussion_locked` Nullable(Bool),
    `latest_merge_request_diff_id` Nullable(Int64),
    `allow_maintainer_to_push` Nullable(Bool) DEFAULT true,
    `state_id` Int16 DEFAULT 1,
    `rebase_jid` Nullable(String),
    `squash_commit_sha` Nullable(String),
    `merge_ref_sha` Nullable(String),
    `draft` Bool DEFAULT false,
    `prepared_at` Nullable(DateTime64(6, 'UTC')),
    `merged_commit_sha` Nullable(String),
    `override_requested_changes` Bool DEFAULT false,
    `head_pipeline_id` Nullable(Int64),
    `imported_from` Int16 DEFAULT 0,
    `retargeted` Bool DEFAULT false,
    `traversal_path` String DEFAULT multiIf(coalesce(target_project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', target_project_id, '0/'), '0/'),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `_siphon_deleted` Bool DEFAULT false
)
ENGINE = `Null`;

CREATE TABLE siphon_merge_requests_closing_issues
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `merge_request_id` Int64,
    `issue_id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `from_mr_description` Bool DEFAULT true CODEC(ZSTD(1)),
    `project_id` Int64,
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, issue_id, id)
ORDER BY (traversal_path, issue_id, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_milestones
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `title` String CODEC(ZSTD(3)),
    `project_id` Nullable(Int64),
    `description` String CODEC(ZSTD(3)),
    `due_date` Nullable(Date32),
    `created_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `state` LowCardinality(String),
    `iid` Int64,
    `start_date` Nullable(Date32),
    `group_id` Nullable(Int64),
    `lock_version` Int64 DEFAULT 0,
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), coalesce(group_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', group_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, id)
ORDER BY (traversal_path, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

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
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `_siphon_deleted` Bool DEFAULT false,
    `state_metadata` String DEFAULT '{}',
    `deletion_scheduled_at` Nullable(DateTime64(6, 'UTC'))
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY namespace_id
ORDER BY namespace_id
SETTINGS index_granularity = 2048;

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
    `organization_id` Int64 DEFAULT 0,
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `_siphon_deleted` Bool DEFAULT false,
    `state` Int8
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY id
ORDER BY id
SETTINGS index_granularity = 2048;

CREATE TABLE siphon_notes
(
    `note` String CODEC(ZSTD(3)),
    `noteable_type` LowCardinality(String),
    `author_id` Nullable(Int64),
    `created_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `project_id` Nullable(Int64),
    `line_code` Nullable(String),
    `commit_id` Nullable(String),
    `noteable_id` Int64,
    `system` Bool DEFAULT false CODEC(ZSTD(1)),
    `st_diff` Nullable(String),
    `updated_by_id` Nullable(Int64),
    `type` LowCardinality(String),
    `position` Nullable(String),
    `original_position` Nullable(String),
    `resolved_at` Nullable(DateTime64(6, 'UTC')),
    `resolved_by_id` Nullable(Int64),
    `discussion_id` String CODEC(ZSTD(1)),
    `change_position` Nullable(String),
    `resolved_by_push` Nullable(Bool) CODEC(ZSTD(1)),
    `review_id` Nullable(Int64),
    `confidential` Bool CODEC(ZSTD(1)),
    `last_edited_at` Nullable(DateTime64(6, 'UTC')),
    `internal` Bool DEFAULT false CODEC(ZSTD(1)),
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `namespace_id` Nullable(Int64),
    `imported_from` Int8 DEFAULT 0,
    `organization_id` Nullable(Int64),
    `traversal_path` String DEFAULT multiIf(coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, noteable_type, noteable_id, id)
ORDER BY (traversal_path, noteable_type, noteable_id, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_organizations
(
    `id` Int64,
    `created_at` DateTime64(6, 'UTC'),
    `updated_at` DateTime64(6, 'UTC'),
    `name` String DEFAULT '',
    `path` String DEFAULT '',
    `visibility_level` Int8 DEFAULT 0,
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `_siphon_deleted` Bool DEFAULT false,
    `state` Int16 DEFAULT 0
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY id
ORDER BY id
SETTINGS index_granularity = 512;

CREATE TABLE siphon_p_ci_builds
(
    `status` LowCardinality(String) DEFAULT '',
    `finished_at` Nullable(DateTime64(6, 'UTC')),
    `created_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `started_at` Nullable(DateTime64(6, 'UTC')),
    `coverage` Nullable(Float64),
    `name` Nullable(String),
    `options` Nullable(String),
    `allow_failure` Bool DEFAULT false CODEC(ZSTD(1)),
    `stage_idx` Nullable(Int64),
    `tag` Nullable(Bool) CODEC(ZSTD(1)),
    `ref` Nullable(String),
    `type` LowCardinality(String) DEFAULT '',
    `target_url` Nullable(String),
    `description` Nullable(String) CODEC(ZSTD(3)),
    `erased_at` Nullable(DateTime64(6, 'UTC')),
    `artifacts_expire_at` Nullable(DateTime64(6, 'UTC')),
    `environment` LowCardinality(String) DEFAULT '',
    `when` LowCardinality(String) DEFAULT '',
    `yaml_variables` Nullable(String),
    `queued_at` Nullable(DateTime64(6, 'UTC')),
    `lock_version` Int64 DEFAULT 0,
    `coverage_regex` Nullable(String),
    `retried` Nullable(Bool) CODEC(ZSTD(1)),
    `protected` Nullable(Bool) CODEC(ZSTD(1)),
    `failure_reason` Nullable(Int64),
    `scheduled_at` Nullable(DateTime64(6, 'UTC')),
    `token_encrypted` Nullable(String),
    `resource_group_id` Nullable(Int64),
    `waiting_for_resource_at` Nullable(DateTime64(6, 'UTC')),
    `processed` Nullable(Bool) CODEC(ZSTD(1)),
    `scheduling_type` Nullable(Int16),
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `stage_id` Nullable(Int64),
    `partition_id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `auto_canceled_by_partition_id` Nullable(Int64),
    `auto_canceled_by_id` Nullable(Int64),
    `commit_id` Nullable(Int64),
    `erased_by_id` Nullable(Int64),
    `project_id` Int64,
    `runner_id` Nullable(Int64),
    `upstream_pipeline_id` Nullable(Int64),
    `user_id` Nullable(Int64),
    `execution_config_id` Nullable(Int64),
    `upstream_pipeline_partition_id` Nullable(Int64),
    `scoped_user_id` Nullable(Int64),
    `timeout` Nullable(Int64),
    `timeout_source` Nullable(Int16),
    `exit_code` Nullable(Int16),
    `debug_trace_enabled` Nullable(Bool) CODEC(ZSTD(1)),
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY
            id,
            partition_id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, id, partition_id)
ORDER BY (traversal_path, id, partition_id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_p_ci_pipelines
(
    `ref` Nullable(String),
    `sha` Nullable(String),
    `before_sha` Nullable(String),
    `created_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `tag` Nullable(Bool) DEFAULT false CODEC(ZSTD(1)),
    `yaml_errors` Nullable(String),
    `committed_at` Nullable(DateTime64(6, 'UTC')),
    `project_id` Int64,
    `status` LowCardinality(String) DEFAULT '',
    `started_at` Nullable(DateTime64(6, 'UTC')),
    `finished_at` Nullable(DateTime64(6, 'UTC')),
    `duration` Nullable(Int64),
    `user_id` Nullable(Int64),
    `lock_version` Int64 DEFAULT 0,
    `pipeline_schedule_id` Nullable(Int64),
    `source` Nullable(Int64),
    `config_source` Nullable(Int64),
    `protected` Nullable(Bool) CODEC(ZSTD(1)),
    `failure_reason` Nullable(Int64),
    `iid` Nullable(Int64),
    `merge_request_id` Nullable(Int64),
    `source_sha` Nullable(String),
    `target_sha` Nullable(String),
    `external_pull_request_id` Nullable(Int64),
    `ci_ref_id` Nullable(Int64),
    `locked` Int16 DEFAULT 1,
    `partition_id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `auto_canceled_by_id` Nullable(Int64),
    `auto_canceled_by_partition_id` Nullable(Int64),
    `trigger_id` Nullable(Int64),
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY
            id,
            partition_id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, id, partition_id)
ORDER BY (traversal_path, id, partition_id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_p_ci_stages
(
    `project_id` Int64,
    `created_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `name` Nullable(String),
    `status` Nullable(Int64),
    `lock_version` Int64 DEFAULT 0,
    `position` Nullable(Int64),
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `partition_id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `pipeline_id` Nullable(Int64),
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY
            id,
            partition_id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, id, partition_id)
ORDER BY (traversal_path, id, partition_id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_project_authorizations
(
    `user_id` Int64,
    `project_id` Int64,
    `access_level` Int64,
    `is_unique` Nullable(Bool),
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/'),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `_siphon_deleted` Bool DEFAULT false,
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY
            user_id,
            project_id,
            access_level
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, user_id, project_id, access_level)
ORDER BY (traversal_path, user_id, project_id, access_level)
SETTINGS deduplicate_merge_projection_mode = 'rebuild', index_granularity = 2048;

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
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `_siphon_deleted` Bool DEFAULT false,
    PROJECTION by_project_namespace_id
    (
        SELECT *
        ORDER BY project_namespace_id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY id
ORDER BY id
SETTINGS deduplicate_merge_projection_mode = 'rebuild', index_granularity = 2048;

CREATE TABLE siphon_routes
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `source_id` Int64 CODEC(ZSTD(1)),
    `source_type` LowCardinality(String) CODEC(LZ4),
    `path` String CODEC(ZSTD(3)),
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `name` String,
    `namespace_id` Int64,
    `traversal_path` String DEFAULT multiIf(coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, source_type, source_id, id)
ORDER BY (traversal_path, source_type, source_id, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_security_findings
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `scan_id` Int64,
    `scanner_id` Int64,
    `severity` Int16,
    `deduplicated` Bool DEFAULT false CODEC(ZSTD(1)),
    `uuid` UUID,
    `overridden_uuid` Nullable(UUID),
    `partition_number` Int64 DEFAULT 1,
    `finding_data` String DEFAULT '{}',
    `project_id` Int64 DEFAULT 0,
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    `scanner_reported_severity` Int16 DEFAULT 0,
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY
            id,
            partition_number
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, id, partition_number)
ORDER BY (traversal_path, id, partition_number)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_security_scans
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `build_id` Int64,
    `scan_type` Int16,
    `info` String DEFAULT '{}',
    `project_id` Int64,
    `pipeline_id` Nullable(Int64),
    `latest` Bool DEFAULT true CODEC(ZSTD(1)),
    `status` Int16 DEFAULT 0,
    `findings_partition_number` Int64 DEFAULT 1,
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, id)
ORDER BY (traversal_path, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_users
(
    `id` Int64,
    `email` String DEFAULT '',
    `sign_in_count` Int64 DEFAULT 0,
    `current_sign_in_at` Nullable(DateTime64(6, 'UTC')),
    `last_sign_in_at` Nullable(DateTime64(6, 'UTC')),
    `current_sign_in_ip` Nullable(String),
    `last_sign_in_ip` Nullable(String),
    `created_at` Nullable(DateTime64(6, 'UTC')),
    `updated_at` Nullable(DateTime64(6, 'UTC')),
    `name` String DEFAULT '',
    `admin` Bool DEFAULT false,
    `projects_limit` Int64,
    `failed_attempts` Int64 DEFAULT 0,
    `locked_at` Nullable(DateTime64(6, 'UTC')),
    `username` String DEFAULT '',
    `can_create_group` Bool DEFAULT true,
    `can_create_team` Bool DEFAULT true,
    `state` String DEFAULT '',
    `color_scheme_id` Int64 DEFAULT 1,
    `created_by_id` Nullable(Int64),
    `last_credential_check_at` Nullable(DateTime64(6, 'UTC')),
    `avatar` Nullable(String),
    `unconfirmed_email` String DEFAULT '',
    `hide_no_ssh_key` Bool DEFAULT false,
    `admin_email_unsubscribed_at` Nullable(DateTime64(6, 'UTC')),
    `notification_email` Nullable(String),
    `hide_no_password` Bool DEFAULT false,
    `password_automatically_set` Bool DEFAULT false,
    `public_email` Nullable(String),
    `dashboard` Int64 DEFAULT 0,
    `project_view` Int64 DEFAULT 2,
    `consumed_timestep` Nullable(Int64),
    `layout` Int64 DEFAULT 0,
    `hide_project_limit` Bool DEFAULT false,
    `note` Nullable(String),
    `otp_grace_period_started_at` Nullable(DateTime64(6, 'UTC')),
    `external` Bool DEFAULT false,
    `auditor` Bool DEFAULT false,
    `require_two_factor_authentication_from_group` Bool DEFAULT false,
    `two_factor_grace_period` Int64 DEFAULT 48,
    `last_activity_on` Nullable(Date32),
    `notified_of_own_activity` Nullable(Bool) DEFAULT false,
    `preferred_language` Nullable(String),
    `theme_id` Nullable(Int8),
    `accepted_term_id` Nullable(Int64),
    `private_profile` Bool DEFAULT false,
    `roadmap_layout` Nullable(Int8),
    `include_private_contributions` Nullable(Bool),
    `commit_email` Nullable(String),
    `group_view` Nullable(Int64),
    `managing_group_id` Nullable(Int64),
    `first_name` String DEFAULT '',
    `last_name` String DEFAULT '',
    `user_type` Int8 DEFAULT 0,
    `onboarding_in_progress` Bool DEFAULT false,
    `color_mode_id` Int8 DEFAULT 1,
    `composite_identity_enforced` Bool DEFAULT false,
    `organization_id` Int64,
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `_siphon_deleted` Bool DEFAULT false
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY id
ORDER BY id
SETTINGS index_granularity = 2048;

CREATE TABLE siphon_vulnerabilities
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `project_id` Int64,
    `author_id` Int64,
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `title` String CODEC(ZSTD(1)),
    `description` String DEFAULT '' CODEC(ZSTD(3)),
    `state` Int16 DEFAULT 1,
    `severity` Int16,
    `severity_overridden` Nullable(Bool) DEFAULT false CODEC(ZSTD(1)),
    `resolved_by_id` Nullable(Int64),
    `resolved_at` Nullable(DateTime64(6, 'UTC')),
    `report_type` Int16,
    `confirmed_by_id` Nullable(Int64),
    `confirmed_at` Nullable(DateTime64(6, 'UTC')),
    `dismissed_at` Nullable(DateTime64(6, 'UTC')),
    `dismissed_by_id` Nullable(Int64),
    `resolved_on_default_branch` Bool DEFAULT false CODEC(ZSTD(1)),
    `present_on_default_branch` Bool DEFAULT true CODEC(ZSTD(1)),
    `detected_at` Nullable(DateTime64(6, 'UTC')) DEFAULT now64(6, 'UTC'),
    `finding_id` Int64,
    `cvss` Nullable(String) DEFAULT '[]',
    `auto_resolved` Bool DEFAULT false CODEC(ZSTD(1)),
    `uuid` Nullable(UUID),
    `solution` Nullable(String),
    `partition_id` Nullable(Int64) DEFAULT 1,
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, id)
ORDER BY (traversal_path, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_vulnerability_identifiers
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `project_id` Int64,
    `fingerprint` String,
    `external_type` LowCardinality(String),
    `external_id` String,
    `name` String CODEC(ZSTD(1)),
    `url` Nullable(String) CODEC(ZSTD(1)),
    `partition_id` Int64 DEFAULT 1,
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, id)
ORDER BY (traversal_path, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_vulnerability_merge_request_links
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `vulnerability_id` Int64,
    `merge_request_id` Int64,
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `project_id` Int64,
    `vulnerability_occurrence_id` Nullable(Int64),
    `readiness_score` Nullable(Float64),
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, id)
ORDER BY (traversal_path, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_vulnerability_occurrence_identifiers
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `occurrence_id` Int64,
    `identifier_id` Int64,
    `project_id` Int64,
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, id)
ORDER BY (traversal_path, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_vulnerability_occurrences
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `severity` Int16,
    `report_type` Int16,
    `project_id` Int64,
    `scanner_id` Int64,
    `primary_identifier_id` Int64,
    `location_fingerprint` String,
    `name` String CODEC(ZSTD(1)),
    `metadata_version` String,
    `raw_metadata` Nullable(String),
    `vulnerability_id` Nullable(Int64),
    `details` String DEFAULT '{}',
    `description` String DEFAULT '' CODEC(ZSTD(3)),
    `solution` String DEFAULT '' CODEC(ZSTD(3)),
    `cve` Nullable(String),
    `location` Nullable(String),
    `detection_method` Int16 DEFAULT 0,
    `uuid` UUID DEFAULT '00000000-0000-0000-0000-000000000000',
    `initial_pipeline_id` Nullable(Int64),
    `latest_pipeline_id` Nullable(Int64),
    `security_project_tracked_context_id` Nullable(Int64),
    `detected_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `new_uuid` Nullable(UUID),
    `partition_id` Nullable(Int64) DEFAULT 1,
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, id)
ORDER BY (traversal_path, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_vulnerability_scanners
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `project_id` Int64,
    `external_id` String,
    `name` LowCardinality(String) CODEC(ZSTD(1)),
    `vendor` LowCardinality(String) DEFAULT 'GitLab',
    `traversal_path` String DEFAULT multiIf(coalesce(project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, id)
ORDER BY (traversal_path, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_work_item_current_statuses
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `namespace_id` Int64,
    `work_item_id` Int64 CODEC(ZSTD(1)),
    `system_defined_status_id` Nullable(Int64),
    `custom_status_id` Nullable(Int64),
    `updated_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `traversal_path` String DEFAULT multiIf(coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, work_item_id, id)
ORDER BY (traversal_path, work_item_id, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE TABLE siphon_work_item_parent_links
(
    `id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `work_item_id` Int64,
    `work_item_parent_id` Int64 CODEC(DoubleDelta, ZSTD(1)),
    `relative_position` Nullable(Int64),
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `namespace_id` Int64,
    `traversal_path` String DEFAULT multiIf(coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, work_item_parent_id, id)
ORDER BY (traversal_path, work_item_parent_id, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

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
    `version` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
    `deleted` Bool DEFAULT false
)
ENGINE = ReplacingMergeTree(version, deleted)
ORDER BY (namespace_path, user_id, item_id, event, id)
SETTINGS index_granularity = 8192;

CREATE TABLE sync_cursors
(
    `table_name` LowCardinality(String) DEFAULT '',
    `primary_key_value` UInt64 DEFAULT 0,
    `recorded_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC')
)
ENGINE = ReplacingMergeTree(recorded_at)
PRIMARY KEY table_name
ORDER BY table_name
SETTINGS index_granularity = 8192;

CREATE TABLE troubleshoot_job_events
(
    `user_id` UInt64 DEFAULT 0,
    `timestamp` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
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

CREATE TABLE work_items
(
    `id` Int64 CODEC(Delta(8), ZSTD(1)),
    `title` String CODEC(ZSTD(3)),
    `author_id` Nullable(Int64),
    `project_id` Nullable(Int64),
    `created_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `updated_at` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `description` String CODEC(ZSTD(3)),
    `milestone_id` Nullable(Int64),
    `iid` Int64,
    `updated_by_id` Nullable(Int64),
    `weight` Nullable(Int64),
    `confidential` Bool DEFAULT false CODEC(ZSTD(1)),
    `due_date` Nullable(Date32),
    `moved_to_id` Nullable(Int64),
    `time_estimate` Nullable(Int64) DEFAULT 0,
    `relative_position` Nullable(Int64),
    `service_desk_reply_to` Nullable(String),
    `cached_markdown_version` Nullable(Int64),
    `last_edited_at` Nullable(DateTime64(6, 'UTC')),
    `last_edited_by_id` Nullable(Int64),
    `discussion_locked` Nullable(Bool) CODEC(ZSTD(1)),
    `closed_at` Nullable(DateTime64(6, 'UTC')),
    `closed_by_id` Nullable(Int64),
    `state_id` Int16 DEFAULT 1,
    `duplicated_to_id` Nullable(Int64),
    `promoted_to_epic_id` Nullable(Int64),
    `health_status` Nullable(Int16),
    `sprint_id` Nullable(Int64),
    `blocking_issues_count` Int64 DEFAULT 0,
    `upvotes_count` Int64 DEFAULT 0,
    `work_item_type_id` Int64,
    `namespace_id` Int64,
    `start_date` Nullable(Date32),
    `imported_from` Int16 DEFAULT 0,
    `namespace_traversal_ids` Array(Int64) DEFAULT [],
    `traversal_path` String DEFAULT multiIf(coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), '0/') CODEC(ZSTD(3)),
    `_siphon_replicated_at` DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
    `_siphon_deleted` Bool DEFAULT false CODEC(ZSTD(1)),
    `metric_first_mentioned_in_commit_at` Nullable(DateTime64(6, 'UTC')),
    `metric_first_associated_with_milestone_at` Nullable(DateTime64(6, 'UTC')),
    `metric_first_added_to_board_at` Nullable(DateTime64(6, 'UTC')),
    `assignees` Array(UInt64),
    `label_ids` Array(Tuple(
        label_id UInt64,
        created_at DateTime64(6, 'UTC'))),
    `award_emojis` Array(Tuple(
        name String,
        user_id UInt64,
        created_at DateTime64(6, 'UTC'))),
    `system_defined_status_id` Nullable(Int64),
    `custom_status_id` Nullable(Int64),
    PROJECTION pg_pkey_ordered
    (
        SELECT *
        ORDER BY id
    )
)
ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
PRIMARY KEY (traversal_path, id)
ORDER BY (traversal_path, id)
SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';

CREATE MATERIALIZED VIEW agent_platform_sessions_mv TO agent_platform_sessions
(
    `user_id` UInt64,
    `namespace_path` String,
    `project_id` String,
    `session_id` String,
    `flow_type` String,
    `environment` String,
    `created_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8),
    `started_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8),
    `finished_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8),
    `dropped_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8),
    `stopped_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8),
    `resumed_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8)
)
AS SELECT
    user_id,
    namespace_path,
    JSONExtractUInt(extras, 'project_id') AS project_id,
    JSONExtractUInt(extras, 'session_id') AS session_id,
    JSONExtractString(extras, 'flow_type') AS flow_type,
    JSONExtractString(extras, 'environment') AS environment,
    toYear(timestamp) AS session_year,
    anyIfState(toNullable(timestamp), event = 8) AS created_event_at,
    anyIfState(toNullable(timestamp), event = 9) AS started_event_at,
    anyIfState(toNullable(timestamp), event = 19) AS finished_event_at,
    anyIfState(toNullable(timestamp), event = 20) AS dropped_event_at,
    anyIfState(toNullable(timestamp), event = 21) AS stopped_event_at,
    anyIfState(toNullable(timestamp), event = 22) AS resumed_event_at
FROM ai_usage_events
WHERE (event IN (8, 9, 19, 20, 21, 22)) AND (JSONExtractString(extras, 'session_id') != '')
GROUP BY
    namespace_path,
    user_id,
    session_id,
    flow_type,
    project_id,
    environment,
    toYear(timestamp);

CREATE MATERIALIZED VIEW ai_code_suggestions_mv TO ai_code_suggestions
(
    `uid` String,
    `namespace_path` String,
    `user_id` UInt64,
    `timestamp` DateTime64(6, 'UTC'),
    `shown_at` AggregateFunction(minIf, Nullable(DateTime64(6, 'UTC')), UInt8),
    `accepted_at` AggregateFunction(maxIf, Nullable(DateTime64(6, 'UTC')), UInt8),
    `rejected_at` AggregateFunction(maxIf, Nullable(DateTime64(6, 'UTC')), UInt8),
    `language` String,
    `branch_name` String,
    `ide_name` String,
    `ide_vendor` String,
    `ide_version` String,
    `extension_name` String,
    `extension_version` String,
    `language_server_version` String,
    `model_name` String,
    `model_engine` String,
    `suggestion_size` UInt64
)
AS SELECT
    JSONExtractString(extras, 'unique_tracking_id') AS uid,
    namespace_path,
    user_id,
    min(e.timestamp) AS timestamp,
    minIfState(toNullable(e.timestamp), e.event = 2) AS shown_at,
    maxIfState(toNullable(e.timestamp), e.event = 3) AS accepted_at,
    maxIfState(toNullable(e.timestamp), e.event = 4) AS rejected_at,
    any(JSONExtractString(e.extras, 'language')) AS language,
    any(JSONExtractString(e.extras, 'branch_name')) AS branch_name,
    any(JSONExtractString(e.extras, 'ide_name')) AS ide_name,
    any(JSONExtractString(e.extras, 'ide_vendor')) AS ide_vendor,
    any(JSONExtractString(e.extras, 'ide_version')) AS ide_version,
    any(JSONExtractString(e.extras, 'extension_name')) AS extension_name,
    any(JSONExtractString(e.extras, 'extension_version')) AS extension_version,
    any(JSONExtractString(e.extras, 'language_server_version')) AS language_server_version,
    any(JSONExtractString(e.extras, 'model_name')) AS model_name,
    any(JSONExtractString(e.extras, 'model_engine')) AS model_engine,
    max(JSONExtractUInt(e.extras, 'suggestion_size')) AS suggestion_size
FROM ai_usage_events AS e
WHERE e.event IN (2, 3, 4)
GROUP BY
    uid,
    e.namespace_path,
    e.user_id;

CREATE MATERIALIZED VIEW ai_usage_events_daily_mv TO ai_usage_events_daily
(
    `namespace_path` String,
    `date` Date,
    `event` UInt16,
    `user_id` UInt64,
    `occurrences` UInt8
)
AS SELECT
    namespace_path AS namespace_path,
    toDate(timestamp) AS date,
    event AS event,
    user_id AS user_id,
    1 AS occurrences
FROM ai_usage_events;

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

CREATE MATERIALIZED VIEW code_suggestion_events_daily_new_mv TO code_suggestion_events_daily_new
(
    `namespace_path` String,
    `user_id` UInt64,
    `date` Date,
    `event` UInt16,
    `ide_name` LowCardinality(String),
    `language` LowCardinality(String),
    `suggestions_size_sum` UInt64,
    `occurrences` UInt8
)
AS SELECT
    namespace_path AS namespace_path,
    user_id AS user_id,
    toDate(timestamp) AS date,
    event AS event,
    toLowCardinality(JSONExtractString(extras, 'ide_name')) AS ide_name,
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
    `author_id` Int64,
    `target_type` LowCardinality(String),
    `action` Int16,
    `created_at` DateTime64(6, 'UTC'),
    `updated_at` DateTime64(6, 'UTC'),
    `version` DateTime64(6, 'UTC'),
    `deleted` Bool
)
AS WITH base AS
    (
        SELECT *
        FROM siphon_events
        WHERE ((action IN (5, 6)) AND (target_type = '')) OR ((action IN (1, 3, 7, 12)) AND (target_type IN ('MergeRequest', 'Issue', 'WorkItem')))
    )
SELECT
    base.id AS id,
    base.path AS path,
    base.author_id AS author_id,
    base.target_type AS target_type,
    base.action AS action,
    base.created_at AS created_at,
    base.updated_at AS updated_at,
    base._siphon_replicated_at AS version,
    base._siphon_deleted AS deleted
FROM base;

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

CREATE MATERIALIZED VIEW merge_requests_mv TO merge_requests
(
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
    `iid` Int64,
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
    `time_estimate` Nullable(Int64),
    `squash` Bool,
    `cached_markdown_version` Nullable(Int64),
    `last_edited_at` Nullable(DateTime64(6, 'UTC')),
    `last_edited_by_id` Nullable(Int64),
    `merge_jid` String,
    `discussion_locked` Nullable(Bool),
    `latest_merge_request_diff_id` Nullable(Int64),
    `allow_maintainer_to_push` Nullable(Bool),
    `state_id` Int16,
    `rebase_jid` Nullable(String),
    `squash_commit_sha` Nullable(String),
    `merge_ref_sha` Nullable(String),
    `draft` Bool,
    `prepared_at` Nullable(DateTime64(6, 'UTC')),
    `merged_commit_sha` Nullable(String),
    `override_requested_changes` Bool,
    `head_pipeline_id` Nullable(Int64),
    `imported_from` Int16,
    `retargeted` Bool,
    `traversal_path` String,
    `_siphon_replicated_at` DateTime64(6, 'UTC'),
    `_siphon_deleted` Bool,
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
    `metric_reviewer_first_assigned_at` Nullable(DateTime64(6, 'UTC')),
    `reviewers` Array(Tuple(
        Int64,
        Int16,
        DateTime64(6, 'UTC'))),
    `assignees` Array(Tuple(
        Int64,
        DateTime64(6, 'UTC'))),
    `approvals` Array(Tuple(
        Int64,
        DateTime64(6, 'UTC'))),
    `label_ids` Array(Tuple(
        Int64,
        DateTime64(6, 'UTC'))),
    `award_emojis` Array(Tuple(
        String,
        Int64,
        DateTime64(6, 'UTC')))
)
AS WITH
    base AS
    (
        SELECT *
        FROM siphon_merge_requests
    ),
    siphon_merge_request_metrics_cte AS
    (
        SELECT
            traversal_path,
            merge_request_id,
            id,
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
            argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
        FROM siphon_merge_request_metrics
        WHERE (traversal_path, merge_request_id) IN (
            SELECT
                traversal_path,
                id
            FROM base
        )
        GROUP BY
            traversal_path,
            merge_request_id,
            id
        HAVING deleted = false
    ),
    siphon_merge_request_reviewers_cte AS
    (
        SELECT
            traversal_path,
            merge_request_id,
            groupArray((user_id, state, created_at)) AS reviewers
        FROM
        (
            SELECT
                traversal_path,
                merge_request_id,
                id,
                argMax(user_id, _siphon_replicated_at) AS user_id,
                argMax(state, _siphon_replicated_at) AS state,
                argMax(created_at, _siphon_replicated_at) AS created_at,
                argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
            FROM siphon_merge_request_reviewers
            WHERE (traversal_path, merge_request_id) IN (
                SELECT
                    traversal_path,
                    id
                FROM base
            )
            GROUP BY
                traversal_path,
                merge_request_id,
                id
            HAVING deleted = false
        )
        GROUP BY
            traversal_path,
            merge_request_id
    ),
    siphon_merge_request_assignees_cte AS
    (
        SELECT
            traversal_path,
            merge_request_id,
            groupArray((user_id, created_at)) AS assignees
        FROM
        (
            SELECT
                traversal_path,
                merge_request_id,
                id,
                argMax(user_id, _siphon_replicated_at) AS user_id,
                argMax(created_at, _siphon_replicated_at) AS created_at,
                argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
            FROM siphon_merge_request_assignees
            WHERE (traversal_path, merge_request_id) IN (
                SELECT
                    traversal_path,
                    id
                FROM base
            )
            GROUP BY
                traversal_path,
                merge_request_id,
                id
            HAVING deleted = false
        )
        GROUP BY
            traversal_path,
            merge_request_id
    ),
    siphon_approvals_cte AS
    (
        SELECT
            traversal_path,
            merge_request_id,
            groupArray((user_id, created_at)) AS approvals
        FROM
        (
            SELECT
                traversal_path,
                merge_request_id,
                id,
                argMax(user_id, _siphon_replicated_at) AS user_id,
                argMax(created_at, _siphon_replicated_at) AS created_at,
                argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
            FROM siphon_approvals
            WHERE (traversal_path, merge_request_id) IN (
                SELECT
                    traversal_path,
                    id
                FROM base
            )
            GROUP BY
                traversal_path,
                merge_request_id,
                id
            HAVING deleted = false
        )
        GROUP BY
            traversal_path,
            merge_request_id
    ),
    siphon_label_links_cte AS
    (
        SELECT
            traversal_path,
            target_id AS merge_request_id,
            groupArray((label_id, created_at)) AS label_ids
        FROM
        (
            SELECT
                traversal_path,
                target_type,
                target_id,
                id,
                argMax(label_id, _siphon_replicated_at) AS label_id,
                argMax(created_at, _siphon_replicated_at) AS created_at,
                argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
            FROM siphon_label_links
            WHERE (traversal_path, target_type, target_id) IN (
                SELECT
                    traversal_path,
                    'MergeRequest' AS target_type,
                    id AS target_id
                FROM base
            )
            GROUP BY
                traversal_path,
                target_type,
                target_id,
                id
            HAVING deleted = false
        )
        GROUP BY
            traversal_path,
            target_id
    ),
    siphon_award_emoji_cte AS
    (
        SELECT
            traversal_path,
            awardable_id AS merge_request_id,
            groupArray((name, user_id, created_at)) AS award_emojis
        FROM
        (
            SELECT
                traversal_path,
                awardable_type,
                awardable_id,
                id,
                argMax(name, _siphon_replicated_at) AS name,
                argMax(user_id, _siphon_replicated_at) AS user_id,
                argMax(created_at, _siphon_replicated_at) AS created_at,
                argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
            FROM siphon_award_emoji
            WHERE (traversal_path, awardable_type, awardable_id) IN (
                SELECT
                    traversal_path,
                    'MergeRequest' AS awardable_type,
                    id AS awardable_id
                FROM base
            )
            GROUP BY
                traversal_path,
                awardable_type,
                awardable_id,
                id
            HAVING deleted = false
        )
        GROUP BY
            traversal_path,
            awardable_id
    )
SELECT
    base.id AS id,
    base.target_branch AS target_branch,
    base.source_branch AS source_branch,
    base.source_project_id AS source_project_id,
    base.author_id AS author_id,
    base.assignee_id AS assignee_id,
    base.title AS title,
    base.created_at AS created_at,
    base.updated_at AS updated_at,
    base.milestone_id AS milestone_id,
    base.merge_status AS merge_status,
    base.target_project_id AS target_project_id,
    base.iid AS iid,
    base.description AS description,
    base.updated_by_id AS updated_by_id,
    base.merge_error AS merge_error,
    base.merge_params AS merge_params,
    base.merge_when_pipeline_succeeds AS merge_when_pipeline_succeeds,
    base.merge_user_id AS merge_user_id,
    base.merge_commit_sha AS merge_commit_sha,
    base.approvals_before_merge AS approvals_before_merge,
    base.rebase_commit_sha AS rebase_commit_sha,
    base.in_progress_merge_commit_sha AS in_progress_merge_commit_sha,
    base.time_estimate AS time_estimate,
    base.squash AS squash,
    base.cached_markdown_version AS cached_markdown_version,
    base.last_edited_at AS last_edited_at,
    base.last_edited_by_id AS last_edited_by_id,
    base.merge_jid AS merge_jid,
    base.discussion_locked AS discussion_locked,
    base.latest_merge_request_diff_id AS latest_merge_request_diff_id,
    base.allow_maintainer_to_push AS allow_maintainer_to_push,
    base.state_id AS state_id,
    base.rebase_jid AS rebase_jid,
    base.squash_commit_sha AS squash_commit_sha,
    base.merge_ref_sha AS merge_ref_sha,
    base.draft AS draft,
    base.prepared_at AS prepared_at,
    base.merged_commit_sha AS merged_commit_sha,
    base.override_requested_changes AS override_requested_changes,
    base.head_pipeline_id AS head_pipeline_id,
    base.imported_from AS imported_from,
    base.retargeted AS retargeted,
    base.traversal_path AS traversal_path,
    base._siphon_replicated_at AS _siphon_replicated_at,
    base._siphon_deleted AS _siphon_deleted,
    siphon_merge_request_metrics_cte.latest_build_started_at AS metric_latest_build_started_at,
    siphon_merge_request_metrics_cte.latest_build_finished_at AS metric_latest_build_finished_at,
    siphon_merge_request_metrics_cte.first_deployed_to_production_at AS metric_first_deployed_to_production_at,
    siphon_merge_request_metrics_cte.merged_at AS metric_merged_at,
    siphon_merge_request_metrics_cte.merged_by_id AS metric_merged_by_id,
    siphon_merge_request_metrics_cte.latest_closed_by_id AS metric_latest_closed_by_id,
    siphon_merge_request_metrics_cte.latest_closed_at AS metric_latest_closed_at,
    siphon_merge_request_metrics_cte.first_comment_at AS metric_first_comment_at,
    siphon_merge_request_metrics_cte.first_commit_at AS metric_first_commit_at,
    siphon_merge_request_metrics_cte.last_commit_at AS metric_last_commit_at,
    siphon_merge_request_metrics_cte.diff_size AS metric_diff_size,
    siphon_merge_request_metrics_cte.modified_paths_size AS metric_modified_paths_size,
    siphon_merge_request_metrics_cte.commits_count AS metric_commits_count,
    siphon_merge_request_metrics_cte.first_approved_at AS metric_first_approved_at,
    siphon_merge_request_metrics_cte.first_reassigned_at AS metric_first_reassigned_at,
    siphon_merge_request_metrics_cte.added_lines AS metric_added_lines,
    siphon_merge_request_metrics_cte.removed_lines AS metric_removed_lines,
    siphon_merge_request_metrics_cte.first_contribution AS metric_first_contribution,
    siphon_merge_request_metrics_cte.pipeline_id AS metric_pipeline_id,
    siphon_merge_request_metrics_cte.reviewer_first_assigned_at AS metric_reviewer_first_assigned_at,
    siphon_merge_request_reviewers_cte.reviewers AS reviewers,
    siphon_merge_request_assignees_cte.assignees AS assignees,
    siphon_approvals_cte.approvals AS approvals,
    siphon_label_links_cte.label_ids AS label_ids,
    siphon_award_emoji_cte.award_emojis AS award_emojis
FROM base
LEFT JOIN siphon_merge_request_metrics_cte ON (base.traversal_path = siphon_merge_request_metrics_cte.traversal_path) AND (base.id = siphon_merge_request_metrics_cte.merge_request_id)
LEFT JOIN siphon_merge_request_reviewers_cte ON (base.traversal_path = siphon_merge_request_reviewers_cte.traversal_path) AND (base.id = siphon_merge_request_reviewers_cte.merge_request_id)
LEFT JOIN siphon_merge_request_assignees_cte ON (base.traversal_path = siphon_merge_request_assignees_cte.traversal_path) AND (base.id = siphon_merge_request_assignees_cte.merge_request_id)
LEFT JOIN siphon_approvals_cte ON (base.traversal_path = siphon_approvals_cte.traversal_path) AND (base.id = siphon_approvals_cte.merge_request_id)
LEFT JOIN siphon_label_links_cte ON (base.traversal_path = siphon_label_links_cte.traversal_path) AND (base.id = siphon_label_links_cte.merge_request_id)
LEFT JOIN siphon_award_emoji_cte ON (base.traversal_path = siphon_award_emoji_cte.traversal_path) AND (base.id = siphon_award_emoji_cte.merge_request_id);

CREATE MATERIALIZED VIEW namespace_traversal_path_refresh_to_projects_mv TO siphon_projects
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
    `visibility_level` Int64,
    `archived` Bool,
    `avatar` Nullable(String),
    `merge_requests_template` Nullable(String),
    `star_count` Int64,
    `merge_requests_rebase_enabled` Nullable(Bool),
    `import_type` Nullable(String),
    `import_source` Nullable(String),
    `approvals_before_merge` Int64,
    `reset_approvals_on_push` Nullable(Bool),
    `merge_requests_ff_only_enabled` Nullable(Bool),
    `issues_template` Nullable(String),
    `mirror` Bool,
    `mirror_last_update_at` Nullable(DateTime64(6, 'UTC')),
    `mirror_last_successful_update_at` Nullable(DateTime64(6, 'UTC')),
    `mirror_user_id` Nullable(Int64),
    `shared_runners_enabled` Bool,
    `build_allow_git_fetch` Bool,
    `build_timeout` Int64,
    `mirror_trigger_builds` Bool,
    `pending_delete` Nullable(Bool),
    `public_builds` Bool,
    `last_repository_check_failed` Nullable(Bool),
    `last_repository_check_at` Nullable(DateTime64(6, 'UTC')),
    `only_allow_merge_if_pipeline_succeeds` Bool,
    `has_external_issue_tracker` Nullable(Bool),
    `repository_storage` String,
    `repository_read_only` Nullable(Bool),
    `request_access_enabled` Bool,
    `has_external_wiki` Nullable(Bool),
    `ci_config_path` Nullable(String),
    `lfs_enabled` Nullable(Bool),
    `description_html` Nullable(String),
    `only_allow_merge_if_all_discussions_are_resolved` Nullable(Bool),
    `repository_size_limit` Nullable(Int64),
    `printing_merge_request_link_enabled` Bool,
    `auto_cancel_pending_pipelines` Int64,
    `service_desk_enabled` Nullable(Bool),
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
    `pages_https_only` Nullable(Bool),
    `packages_enabled` Nullable(Bool),
    `merge_requests_author_approval` Nullable(Bool),
    `pool_repository_id` Nullable(Int64),
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
    `hidden` Bool,
    `organization_id` Nullable(Int64),
    `_siphon_deleted` Bool,
    `_siphon_replicated_at` DateTime64(6)
)
AS WITH
    base AS
    (
        SELECT id
        FROM siphon_namespaces
        WHERE type = 'Project'
    ),
    projects AS
    (
        SELECT
            id,
            argMax(name, _siphon_replicated_at) AS name,
            argMax(path, _siphon_replicated_at) AS path,
            argMax(description, _siphon_replicated_at) AS description,
            argMax(created_at, _siphon_replicated_at) AS created_at,
            argMax(updated_at, _siphon_replicated_at) AS updated_at,
            argMax(creator_id, _siphon_replicated_at) AS creator_id,
            argMax(namespace_id, _siphon_replicated_at) AS namespace_id,
            argMax(last_activity_at, _siphon_replicated_at) AS last_activity_at,
            argMax(import_url, _siphon_replicated_at) AS import_url,
            argMax(visibility_level, _siphon_replicated_at) AS visibility_level,
            argMax(archived, _siphon_replicated_at) AS archived,
            argMax(avatar, _siphon_replicated_at) AS avatar,
            argMax(merge_requests_template, _siphon_replicated_at) AS merge_requests_template,
            argMax(star_count, _siphon_replicated_at) AS star_count,
            argMax(merge_requests_rebase_enabled, _siphon_replicated_at) AS merge_requests_rebase_enabled,
            argMax(import_type, _siphon_replicated_at) AS import_type,
            argMax(import_source, _siphon_replicated_at) AS import_source,
            argMax(approvals_before_merge, _siphon_replicated_at) AS approvals_before_merge,
            argMax(reset_approvals_on_push, _siphon_replicated_at) AS reset_approvals_on_push,
            argMax(merge_requests_ff_only_enabled, _siphon_replicated_at) AS merge_requests_ff_only_enabled,
            argMax(issues_template, _siphon_replicated_at) AS issues_template,
            argMax(mirror, _siphon_replicated_at) AS mirror,
            argMax(mirror_last_update_at, _siphon_replicated_at) AS mirror_last_update_at,
            argMax(mirror_last_successful_update_at, _siphon_replicated_at) AS mirror_last_successful_update_at,
            argMax(mirror_user_id, _siphon_replicated_at) AS mirror_user_id,
            argMax(shared_runners_enabled, _siphon_replicated_at) AS shared_runners_enabled,
            argMax(build_allow_git_fetch, _siphon_replicated_at) AS build_allow_git_fetch,
            argMax(build_timeout, _siphon_replicated_at) AS build_timeout,
            argMax(mirror_trigger_builds, _siphon_replicated_at) AS mirror_trigger_builds,
            argMax(pending_delete, _siphon_replicated_at) AS pending_delete,
            argMax(public_builds, _siphon_replicated_at) AS public_builds,
            argMax(last_repository_check_failed, _siphon_replicated_at) AS last_repository_check_failed,
            argMax(last_repository_check_at, _siphon_replicated_at) AS last_repository_check_at,
            argMax(only_allow_merge_if_pipeline_succeeds, _siphon_replicated_at) AS only_allow_merge_if_pipeline_succeeds,
            argMax(has_external_issue_tracker, _siphon_replicated_at) AS has_external_issue_tracker,
            argMax(repository_storage, _siphon_replicated_at) AS repository_storage,
            argMax(repository_read_only, _siphon_replicated_at) AS repository_read_only,
            argMax(request_access_enabled, _siphon_replicated_at) AS request_access_enabled,
            argMax(has_external_wiki, _siphon_replicated_at) AS has_external_wiki,
            argMax(ci_config_path, _siphon_replicated_at) AS ci_config_path,
            argMax(lfs_enabled, _siphon_replicated_at) AS lfs_enabled,
            argMax(description_html, _siphon_replicated_at) AS description_html,
            argMax(only_allow_merge_if_all_discussions_are_resolved, _siphon_replicated_at) AS only_allow_merge_if_all_discussions_are_resolved,
            argMax(repository_size_limit, _siphon_replicated_at) AS repository_size_limit,
            argMax(printing_merge_request_link_enabled, _siphon_replicated_at) AS printing_merge_request_link_enabled,
            argMax(auto_cancel_pending_pipelines, _siphon_replicated_at) AS auto_cancel_pending_pipelines,
            argMax(service_desk_enabled, _siphon_replicated_at) AS service_desk_enabled,
            argMax(cached_markdown_version, _siphon_replicated_at) AS cached_markdown_version,
            argMax(delete_error, _siphon_replicated_at) AS delete_error,
            argMax(last_repository_updated_at, _siphon_replicated_at) AS last_repository_updated_at,
            argMax(disable_overriding_approvers_per_merge_request, _siphon_replicated_at) AS disable_overriding_approvers_per_merge_request,
            argMax(storage_version, _siphon_replicated_at) AS storage_version,
            argMax(resolve_outdated_diff_discussions, _siphon_replicated_at) AS resolve_outdated_diff_discussions,
            argMax(remote_mirror_available_overridden, _siphon_replicated_at) AS remote_mirror_available_overridden,
            argMax(only_mirror_protected_branches, _siphon_replicated_at) AS only_mirror_protected_branches,
            argMax(pull_mirror_available_overridden, _siphon_replicated_at) AS pull_mirror_available_overridden,
            argMax(jobs_cache_index, _siphon_replicated_at) AS jobs_cache_index,
            argMax(external_authorization_classification_label, _siphon_replicated_at) AS external_authorization_classification_label,
            argMax(mirror_overwrites_diverged_branches, _siphon_replicated_at) AS mirror_overwrites_diverged_branches,
            argMax(pages_https_only, _siphon_replicated_at) AS pages_https_only,
            argMax(packages_enabled, _siphon_replicated_at) AS packages_enabled,
            argMax(merge_requests_author_approval, _siphon_replicated_at) AS merge_requests_author_approval,
            argMax(pool_repository_id, _siphon_replicated_at) AS pool_repository_id,
            argMax(bfg_object_map, _siphon_replicated_at) AS bfg_object_map,
            argMax(detected_repository_languages, _siphon_replicated_at) AS detected_repository_languages,
            argMax(merge_requests_disable_committers_approval, _siphon_replicated_at) AS merge_requests_disable_committers_approval,
            argMax(require_password_to_approve, _siphon_replicated_at) AS require_password_to_approve,
            argMax(emails_disabled, _siphon_replicated_at) AS emails_disabled,
            argMax(max_pages_size, _siphon_replicated_at) AS max_pages_size,
            argMax(max_artifacts_size, _siphon_replicated_at) AS max_artifacts_size,
            argMax(pull_mirror_branch_prefix, _siphon_replicated_at) AS pull_mirror_branch_prefix,
            argMax(remove_source_branch_after_merge, _siphon_replicated_at) AS remove_source_branch_after_merge,
            argMax(marked_for_deletion_at, _siphon_replicated_at) AS marked_for_deletion_at,
            argMax(marked_for_deletion_by_user_id, _siphon_replicated_at) AS marked_for_deletion_by_user_id,
            argMax(autoclose_referenced_issues, _siphon_replicated_at) AS autoclose_referenced_issues,
            argMax(suggestion_commit_message, _siphon_replicated_at) AS suggestion_commit_message,
            argMax(project_namespace_id, _siphon_replicated_at) AS project_namespace_id,
            argMax(hidden, _siphon_replicated_at) AS hidden,
            argMax(organization_id, _siphon_replicated_at) AS organization_id,
            argMax(_siphon_deleted, _siphon_replicated_at) AS deleted,
            now64(6) AS _siphon_replicated_at
        FROM
        (
            SELECT *
            FROM siphon_projects
            WHERE project_namespace_id IN (
                SELECT id
                FROM base
            )
        )
        GROUP BY id
        HAVING deleted = false
    )
SELECT
    projects.id AS id,
    projects.name AS name,
    projects.path AS path,
    projects.description AS description,
    projects.created_at AS created_at,
    projects.updated_at AS updated_at,
    projects.creator_id AS creator_id,
    projects.namespace_id AS namespace_id,
    projects.last_activity_at AS last_activity_at,
    projects.import_url AS import_url,
    projects.visibility_level AS visibility_level,
    projects.archived AS archived,
    projects.avatar AS avatar,
    projects.merge_requests_template AS merge_requests_template,
    projects.star_count AS star_count,
    projects.merge_requests_rebase_enabled AS merge_requests_rebase_enabled,
    projects.import_type AS import_type,
    projects.import_source AS import_source,
    projects.approvals_before_merge AS approvals_before_merge,
    projects.reset_approvals_on_push AS reset_approvals_on_push,
    projects.merge_requests_ff_only_enabled AS merge_requests_ff_only_enabled,
    projects.issues_template AS issues_template,
    projects.mirror AS mirror,
    projects.mirror_last_update_at AS mirror_last_update_at,
    projects.mirror_last_successful_update_at AS mirror_last_successful_update_at,
    projects.mirror_user_id AS mirror_user_id,
    projects.shared_runners_enabled AS shared_runners_enabled,
    projects.build_allow_git_fetch AS build_allow_git_fetch,
    projects.build_timeout AS build_timeout,
    projects.mirror_trigger_builds AS mirror_trigger_builds,
    projects.pending_delete AS pending_delete,
    projects.public_builds AS public_builds,
    projects.last_repository_check_failed AS last_repository_check_failed,
    projects.last_repository_check_at AS last_repository_check_at,
    projects.only_allow_merge_if_pipeline_succeeds AS only_allow_merge_if_pipeline_succeeds,
    projects.has_external_issue_tracker AS has_external_issue_tracker,
    projects.repository_storage AS repository_storage,
    projects.repository_read_only AS repository_read_only,
    projects.request_access_enabled AS request_access_enabled,
    projects.has_external_wiki AS has_external_wiki,
    projects.ci_config_path AS ci_config_path,
    projects.lfs_enabled AS lfs_enabled,
    projects.description_html AS description_html,
    projects.only_allow_merge_if_all_discussions_are_resolved AS only_allow_merge_if_all_discussions_are_resolved,
    projects.repository_size_limit AS repository_size_limit,
    projects.printing_merge_request_link_enabled AS printing_merge_request_link_enabled,
    projects.auto_cancel_pending_pipelines AS auto_cancel_pending_pipelines,
    projects.service_desk_enabled AS service_desk_enabled,
    projects.cached_markdown_version AS cached_markdown_version,
    projects.delete_error AS delete_error,
    projects.last_repository_updated_at AS last_repository_updated_at,
    projects.disable_overriding_approvers_per_merge_request AS disable_overriding_approvers_per_merge_request,
    projects.storage_version AS storage_version,
    projects.resolve_outdated_diff_discussions AS resolve_outdated_diff_discussions,
    projects.remote_mirror_available_overridden AS remote_mirror_available_overridden,
    projects.only_mirror_protected_branches AS only_mirror_protected_branches,
    projects.pull_mirror_available_overridden AS pull_mirror_available_overridden,
    projects.jobs_cache_index AS jobs_cache_index,
    projects.external_authorization_classification_label AS external_authorization_classification_label,
    projects.mirror_overwrites_diverged_branches AS mirror_overwrites_diverged_branches,
    projects.pages_https_only AS pages_https_only,
    projects.packages_enabled AS packages_enabled,
    projects.merge_requests_author_approval AS merge_requests_author_approval,
    projects.pool_repository_id AS pool_repository_id,
    projects.bfg_object_map AS bfg_object_map,
    projects.detected_repository_languages AS detected_repository_languages,
    projects.merge_requests_disable_committers_approval AS merge_requests_disable_committers_approval,
    projects.require_password_to_approve AS require_password_to_approve,
    projects.emails_disabled AS emails_disabled,
    projects.max_pages_size AS max_pages_size,
    projects.max_artifacts_size AS max_artifacts_size,
    projects.pull_mirror_branch_prefix AS pull_mirror_branch_prefix,
    projects.remove_source_branch_after_merge AS remove_source_branch_after_merge,
    projects.marked_for_deletion_at AS marked_for_deletion_at,
    projects.marked_for_deletion_by_user_id AS marked_for_deletion_by_user_id,
    projects.autoclose_referenced_issues AS autoclose_referenced_issues,
    projects.suggestion_commit_message AS suggestion_commit_message,
    projects.project_namespace_id AS project_namespace_id,
    projects.hidden AS hidden,
    projects.organization_id AS organization_id,
    projects.deleted AS _siphon_deleted,
    projects._siphon_replicated_at AS _siphon_replicated_at
FROM base
LEFT JOIN projects ON projects.project_namespace_id = base.id;

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

CREATE MATERIALIZED VIEW work_items_mv TO work_items
(
    `id` Int64,
    `title` String,
    `author_id` Nullable(Int64),
    `project_id` Nullable(Int64),
    `created_at` DateTime64(6, 'UTC'),
    `updated_at` DateTime64(6, 'UTC'),
    `description` String,
    `milestone_id` Nullable(Int64),
    `iid` Int64,
    `updated_by_id` Nullable(Int64),
    `weight` Nullable(Int64),
    `confidential` Bool,
    `due_date` Nullable(Date32),
    `moved_to_id` Nullable(Int64),
    `time_estimate` Nullable(Int64),
    `relative_position` Nullable(Int64),
    `service_desk_reply_to` Nullable(String),
    `cached_markdown_version` Nullable(Int64),
    `last_edited_at` Nullable(DateTime64(6, 'UTC')),
    `last_edited_by_id` Nullable(Int64),
    `discussion_locked` Nullable(Bool),
    `closed_at` Nullable(DateTime64(6, 'UTC')),
    `closed_by_id` Nullable(Int64),
    `state_id` Int16,
    `duplicated_to_id` Nullable(Int64),
    `promoted_to_epic_id` Nullable(Int64),
    `health_status` Nullable(Int16),
    `sprint_id` Nullable(Int64),
    `blocking_issues_count` Int64,
    `upvotes_count` Int64,
    `work_item_type_id` Int64,
    `namespace_id` Int64,
    `start_date` Nullable(Date32),
    `imported_from` Int16,
    `namespace_traversal_ids` Array(Int64),
    `traversal_path` String,
    `_siphon_replicated_at` DateTime64(6, 'UTC'),
    `_siphon_deleted` Bool,
    `metric_first_mentioned_in_commit_at` Nullable(DateTime64(6, 'UTC')),
    `metric_first_associated_with_milestone_at` Nullable(DateTime64(6, 'UTC')),
    `metric_first_added_to_board_at` Nullable(DateTime64(6, 'UTC')),
    `assignees` Array(UInt64),
    `label_ids` Array(Tuple(
        UInt64,
        DateTime64(6, 'UTC'))),
    `award_emojis` Array(Tuple(
        String,
        UInt64,
        DateTime64(6, 'UTC'))),
    `system_defined_status_id` Nullable(Int64),
    `custom_status_id` Nullable(Int64)
)
AS WITH
    base AS
    (
        SELECT *
        FROM siphon_issues
    ),
    siphon_work_item_current_statuses_cte AS
    (
        SELECT
            traversal_path,
            work_item_id,
            id,
            argMax(system_defined_status_id, _siphon_replicated_at) AS system_defined_status_id,
            argMax(custom_status_id, _siphon_replicated_at) AS custom_status_id,
            argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
        FROM siphon_work_item_current_statuses
        WHERE (traversal_path, work_item_id) IN (
            SELECT
                traversal_path,
                id
            FROM base
        )
        GROUP BY ALL
        HAVING deleted = false
    ),
    siphon_issue_metrics_cte AS
    (
        SELECT
            traversal_path,
            issue_id,
            id,
            argMax(first_mentioned_in_commit_at, _siphon_replicated_at) AS metric_first_mentioned_in_commit_at,
            argMax(first_associated_with_milestone_at, _siphon_replicated_at) AS metric_first_associated_with_milestone_at,
            argMax(first_added_to_board_at, _siphon_replicated_at) AS metric_first_added_to_board_at,
            argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
        FROM siphon_issue_metrics
        WHERE (traversal_path, issue_id) IN (
            SELECT
                traversal_path,
                id
            FROM base
        )
        GROUP BY ALL
        HAVING deleted = false
    ),
    siphon_issue_assignees_cte AS
    (
        SELECT
            traversal_path,
            issue_id,
            groupArray(toUInt64(user_id)) AS assignees
        FROM
        (
            SELECT
                traversal_path,
                issue_id,
                user_id,
                argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
            FROM siphon_issue_assignees
            WHERE (traversal_path, issue_id) IN (
                SELECT
                    traversal_path,
                    id
                FROM base
            )
            GROUP BY ALL
            HAVING deleted = false
        )
        GROUP BY ALL
    ),
    siphon_label_links_cte AS
    (
        SELECT
            traversal_path,
            target_id AS issue_id,
            groupArray((toUInt64(label_id), created_at)) AS label_ids
        FROM
        (
            SELECT
                traversal_path,
                target_type,
                target_id,
                id,
                argMax(label_id, _siphon_replicated_at) AS label_id,
                argMax(created_at, _siphon_replicated_at) AS created_at,
                argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
            FROM siphon_label_links
            WHERE (traversal_path, target_type, target_id) IN (
                SELECT
                    traversal_path,
                    'Issue' AS target_type,
                    id AS target_id
                FROM base
            )
            GROUP BY ALL
            HAVING deleted = false
        )
        GROUP BY ALL
    ),
    siphon_award_emoji_cte AS
    (
        SELECT
            traversal_path,
            awardable_id AS issue_id,
            groupArray((name, toUInt64(user_id), created_at)) AS award_emojis
        FROM
        (
            SELECT
                traversal_path,
                awardable_type,
                awardable_id,
                id,
                argMax(name, _siphon_replicated_at) AS name,
                argMax(user_id, _siphon_replicated_at) AS user_id,
                argMax(created_at, _siphon_replicated_at) AS created_at,
                argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
            FROM siphon_award_emoji
            WHERE (traversal_path, awardable_type, awardable_id) IN (
                SELECT
                    traversal_path,
                    'Issue' AS awardable_type,
                    id AS awardable_id
                FROM base
            )
            GROUP BY ALL
            HAVING deleted = false
        )
        GROUP BY ALL
    )
SELECT
    base.id AS id,
    base.title AS title,
    base.author_id AS author_id,
    base.project_id AS project_id,
    base.created_at AS created_at,
    base.updated_at AS updated_at,
    base.description AS description,
    base.milestone_id AS milestone_id,
    base.iid AS iid,
    base.updated_by_id AS updated_by_id,
    base.weight AS weight,
    base.confidential AS confidential,
    base.due_date AS due_date,
    base.moved_to_id AS moved_to_id,
    base.time_estimate AS time_estimate,
    base.relative_position AS relative_position,
    base.service_desk_reply_to AS service_desk_reply_to,
    base.cached_markdown_version AS cached_markdown_version,
    base.last_edited_at AS last_edited_at,
    base.last_edited_by_id AS last_edited_by_id,
    base.discussion_locked AS discussion_locked,
    base.closed_at AS closed_at,
    base.closed_by_id AS closed_by_id,
    base.state_id AS state_id,
    base.duplicated_to_id AS duplicated_to_id,
    base.promoted_to_epic_id AS promoted_to_epic_id,
    base.health_status AS health_status,
    base.sprint_id AS sprint_id,
    base.blocking_issues_count AS blocking_issues_count,
    base.upvotes_count AS upvotes_count,
    base.work_item_type_id AS work_item_type_id,
    base.namespace_id AS namespace_id,
    base.start_date AS start_date,
    base.imported_from AS imported_from,
    base.namespace_traversal_ids AS namespace_traversal_ids,
    base.traversal_path AS traversal_path,
    base._siphon_replicated_at AS _siphon_replicated_at,
    base._siphon_deleted AS _siphon_deleted,
    siphon_issue_metrics_cte.metric_first_mentioned_in_commit_at AS metric_first_mentioned_in_commit_at,
    siphon_issue_metrics_cte.metric_first_associated_with_milestone_at AS metric_first_associated_with_milestone_at,
    siphon_issue_metrics_cte.metric_first_added_to_board_at AS metric_first_added_to_board_at,
    siphon_issue_assignees_cte.assignees AS assignees,
    siphon_label_links_cte.label_ids AS label_ids,
    siphon_award_emoji_cte.award_emojis AS award_emojis,
    siphon_work_item_current_statuses_cte.system_defined_status_id AS system_defined_status_id,
    siphon_work_item_current_statuses_cte.custom_status_id AS custom_status_id
FROM base
LEFT JOIN siphon_work_item_current_statuses_cte ON (base.traversal_path = siphon_work_item_current_statuses_cte.traversal_path) AND (base.id = siphon_work_item_current_statuses_cte.work_item_id)
LEFT JOIN siphon_issue_metrics_cte ON (base.traversal_path = siphon_issue_metrics_cte.traversal_path) AND (base.id = siphon_issue_metrics_cte.issue_id)
LEFT JOIN siphon_issue_assignees_cte ON (base.traversal_path = siphon_issue_assignees_cte.traversal_path) AND (base.id = siphon_issue_assignees_cte.issue_id)
LEFT JOIN siphon_label_links_cte ON (base.traversal_path = siphon_label_links_cte.traversal_path) AND (base.id = siphon_label_links_cte.issue_id)
LEFT JOIN siphon_award_emoji_cte ON (base.traversal_path = siphon_award_emoji_cte.traversal_path) AND (base.id = siphon_award_emoji_cte.issue_id)