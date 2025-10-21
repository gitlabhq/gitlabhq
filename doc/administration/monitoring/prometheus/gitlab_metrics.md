---
stage: Shared responsibility based on functional area
group: Shared responsibility based on functional area
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Prometheus metrics
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

To enable the GitLab Prometheus metrics:

1. Sign in to GitLab as a user with administrator access.
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **Metrics and profiling**.
1. Find the **Metrics - Prometheus** section, and select **Enable GitLab Prometheus metrics endpoint**.
1. [Restart GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

For self-compiled installations, you must configure it yourself.

## Collecting the metrics

GitLab monitors its own internal service metrics, and makes them available at the
`/-/metrics` endpoint. Unlike other [Prometheus](https://prometheus.io) exporters, to access
the metrics, the client IP address must be [explicitly allowed](../ip_allowlist.md).

These metrics are enabled and collected for [Linux package](https://docs.gitlab.com/omnibus/)
and Helm chart installations. For self-compiled installations, these metrics must be enabled
manually and collected by a Prometheus server.

For enabling and viewing metrics from Sidekiq nodes, see [Sidekiq metrics](#sidekiq-metrics).

## Metrics available

{{< history >}}

- `caller_id` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/392622) from `redis_hit_miss_operations_total` and `redis_cache_generation_duration_seconds` in GitLab 15.11.

{{< /history >}}

The following metrics are available:

| Metric                                                                         | Type      | Since | Labels                                                                  | Description |
|:-------------------------------------------------------------------------------|:----------|------:|:------------------------------------------------------------------------|:------------|
| `action_cable_active_connections`                                              | Gauge     |  13.4 | `server_mode`                                                           | Number of ActionCable WS clients currently connected |
| `action_cable_broadcasts_total`                                                | Counter   | 13.10 | `server_mode`                                                           | The number of ActionCable broadcasts emitted |
| `action_cable_pool_current_size`                                               | Gauge     |  13.4 | `server_mode`                                                           | Current number of worker threads in ActionCable thread pool |
| `action_cable_pool_largest_size`                                               | Gauge     |  13.4 | `server_mode`                                                           | Largest number of worker threads observed so far in ActionCable thread pool |
| `action_cable_pool_max_size`                                                   | Gauge     |  13.4 | `server_mode`                                                           | Maximum number of worker threads in ActionCable thread pool |
| `action_cable_pool_min_size`                                                   | Gauge     |  13.4 | `server_mode`                                                           | Minimum number of worker threads in ActionCable thread pool |
| `action_cable_pool_pending_tasks`                                              | Gauge     |  13.4 | `server_mode`                                                           | Number of tasks waiting to be executed in ActionCable thread pool |
| `action_cable_pool_tasks_total`                                                | Gauge     |  13.4 | `server_mode`                                                           | Total number of tasks executed in ActionCable thread pool |
| `action_cable_single_client_transmissions_total`                               | Counter   | 13.10 | `server_mode`                                                           | The number of ActionCable messages transmitted to any client in any channel |
| `action_cable_subscription_confirmations_total`                                | Counter   | 13.10 | `server_mode`                                                           | The number of ActionCable subscriptions from clients confirmed |
| `action_cable_subscription_rejections_total`                                   | Counter   | 13.10 | `server_mode`                                                           | The number of ActionCable subscriptions from clients rejected |
| `action_cable_transmitted_bytes_total`                                         | Counter   |  16.0 | `operation`, `channel`                                                  | Total number of bytes transmitted over ActionCable |
| `artifact_report_<report_type>_builds_completed_total`                         | Counter   |  15.3 |                                                                         | Counter of completed CI Builds with report-type artifacts, grouped by report type and labeled by status |
| `auto_devops_pipelines_completed_total`                                        | Counter   |  12.7 |                                                                         | Counter of completed Auto DevOps pipelines, labeled by status |
| `cached_object_operations_total`                                               | Counter   |  15.3 | `controller`, `action`, `endpoint_id`                                   | Total number of objects cached for specific web requests |
| `ci_report_parser_duration_seconds`                                            | Histogram |  13.9 | `parser`                                                                | Time to parse CI/CD report artifacts |
| `dependency_linker_usage`                                                      | Counter   |  16.8 | `used_on`                                                               | The number of times dependency linker is used |
| `email_receiver_error`                                                         | Counter   |  14.1 |                                                                         | Total number of errors when processing incoming emails |
| `failed_login_captcha_total`                                                   | Gauge     |  11.0 |                                                                         | Counter of failed CAPTCHA attempts during login |
| `gitlab_application_rate_limiter_throttle_utilization_ratio`                   | Histogram |  17.6 | `throttle_key`, `peek`, `feature_category`                              | Utilization ratio of a throttle in GitLab Application Rate Limiter. |
| `gitlab_cache_misses_total`                                                    | Counter   |  10.2 | `controller`, `action`, `store`, `endpoint_id`                          | Cache read miss |
| `gitlab_cache_operation_duration_seconds`                                      | Histogram |  10.2 | `operation`, `store`, `endpoint_id`                                     | Cache access time |
| `gitlab_cache_operations_total`                                                | Counter   |  12.2 | `controller`, `action`, `operation`, `store`, `endpoint_id`             | Cache operations by controller or action |
| `gitlab_cache_read_multikey_count`                                             | Histogram |  15.7 | `controller`, `action`, `store`, `endpoint_id`                          | Count of keys in multi-key cache read operations |
| `gitlab_ci_active_jobs`                                                        | Histogram |  14.2 |                                                                         | Count of active jobs when pipeline is created |
| `gitlab_ci_build_trace_errors_total`                                           | Counter   |  14.4 | `error_reason`                                                          | Total amount of different error types on a build trace |
| `gitlab_ci_current_queue_size`                                                 | Gauge     |  16.3 |                                                                         | Current size of initialized CI/CD builds queue |
| `gitlab_ci_job_token_authorization_failures`                                   | Counter   | 17.11 | `same_root_ancestor`                                                    | Count of failed authorization attempts via CI JOB Token |
| `gitlab_ci_job_token_inbound_access`                                           | Counter   |  17.2 |                                                                         | Count of inbound accesses via CI job token |
| `gitlab_ci_pipeline_builder_scoped_variables_duration`                         | Histogram |  14.5 |                                                                         | Time in seconds it takes to create the scoped variables for a CI/CD job |
| `gitlab_ci_pipeline_creation_duration_seconds`                                 | Histogram |  13.0 | `gitlab`                                                                | Time in seconds it takes to create a CI/CD pipeline |
| `gitlab_ci_pipeline_security_orchestration_policy_processing_duration_seconds` | Histogram | 13.12 |                                                                         | Time in seconds it takes to process Security Policies in CI/CD pipeline |
| `gitlab_ci_pipeline_size_builds`                                               | Histogram |  13.1 | `source`                                                                | Total number of builds within a pipeline grouped by a pipeline source |
| `gitlab_ci_queue_depth_total`                                                  | Histogram |  16.3 |                                                                         | Size of a CI/CD builds queue in relation to the operation result |
| `gitlab_ci_queue_iteration_duration_seconds`                                   | Histogram |  16.3 |                                                                         | Time it takes to find a build in CI/CD queue |
| `gitlab_ci_queue_operations_total`                                             | Counter   |  16.3 |                                                                         | Counts all the operations that are happening inside a queue |
| `gitlab_ci_queue_retrieval_duration_seconds`                                   | Histogram |  16.3 |                                                                         | Time it takes to execute a SQL query to retrieve builds queue |
| `gitlab_ci_queue_size_total`                                                   | Histogram |  16.3 |                                                                         | Size of initialized CI/CD builds queue |
| `gitlab_ci_runner_authentication_failure_total`                                | Counter   |  15.2 |                                                                         | Total number of times that runner authentication has failed |
| `gitlab_ci_runner_authentication_success_total`                                | Counter   |  15.2 | `type`                                                                  | Total number of times that runner authentication has succeeded |
| `gitlab_ci_trace_bytes_total`                                                  | Counter   |  13.4 |                                                                         | Total amount of build trace bytes transferred |
| `gitlab_ci_trace_finalize_duration_seconds`                                    | Histogram |  13.6 |                                                                         | Duration of build trace chunks migration to object storage |
| `gitlab_ci_trace_operations_total`                                             | Counter   |  13.4 | `operation`                                                             | Total amount of different operations on a build trace |
| `gitlab_connection_pool_available_count`                                       | Gauge     |  16.7 |                                                                         | Number of available connections in the pool |
| `gitlab_connection_pool_size`                                                  | Gauge     |  16.7 |                                                                         | Size of connection pool |
| `gitlab_database_transaction_seconds`                                          | Histogram |  12.1 |                                                                         | Time spent in database transactions, in seconds |
| `gitlab_dependency_paths_found_total`                                          | Counter   |  18.3 | `cyclic`                                                                | Counts the number of ancestor dependency paths found for a given dependency. |
| `gitlab_diffs_collection_real_duration_seconds`                                | Histogram |  15.8 | `controller`, `action`, `endpoint_id`                                   | Duration in seconds spent on querying merge request diff files on diffs batch request |
| `gitlab_diffs_comparison_real_duration_seconds`                                | Histogram |  15.8 | `controller`, `action`, `endpoint_id`                                   | Duration in seconds spent on getting comparison data on diffs batch request |
| `gitlab_diffs_highlight_cache_decorate_real_duration_seconds`                  | Histogram |  15.8 | `controller`, `action`, `endpoint_id`                                   | Duration in seconds spent on setting highlighted lines from cache on diffs batch request |
| `gitlab_diffs_render_real_duration_seconds`                                    | Histogram |  15.8 | `controller`, `action`, `endpoint_id`                                   | Duration in seconds spent on serializing and rendering diffs on diffs batch request |
| `gitlab_diffs_reorder_real_duration_seconds`                                   | Histogram |  15.8 | `controller`, `action`, `endpoint_id`                                   | Duration in seconds spend on reordering of diff files on diffs batch request |
| `gitlab_diffs_unfold_real_duration_seconds`                                    | Histogram |  15.8 | `controller`, `action`, `endpoint_id`                                   | Duration in seconds spent on unfolding positions on diffs batch request |
| `gitlab_diffs_unfoldable_positions_real_duration_seconds`                      | Histogram |  15.8 | `controller`, `action`                                                  | Duration in seconds spent on getting unfoldable note positions on diffs batch request |
| `gitlab_diffs_write_cache_real_duration_seconds`                               | Histogram |  15.8 | `controller`, `action`, `endpoint_id`                                   | Duration in seconds spent on caching highlighted lines and stats on diffs batch request |
| `gitlab_external_http_duration_seconds`                                        | Counter   |  13.8 |                                                                         | Duration in seconds spent on each HTTP call to external systems |
| `gitlab_external_http_exception_total`                                         | Counter   |  13.8 |                                                                         | Total number of exceptions raised when making external HTTP calls |
| `gitlab_external_http_total`                                                   | Counter   |  13.8 | `controller`, `action`, `endpoint_id`                                   | Total number of HTTP calls to external systems |
| `gitlab_find_dependency_paths_real_duration_seconds`                           | Histogram |  18.3 |                                                                         | Duration in seconds spent resolving the ancestor dependency paths for a given component. |
| `gitlab_ghost_user_migration_lag_seconds`                                      | Gauge     |  15.6 |                                                                         | The waiting time in seconds of the oldest scheduled record for ghost user migration |
| `gitlab_ghost_user_migration_scheduled_records_total`                          | Gauge     |  15.6 |                                                                         | The total number of scheduled ghost user migrations |
| `gitlab_highlight_usage`                                                       | Counter   |  16.8 | `used_on`                                                               | The number of times `Gitlab::Highlight` is used |
| `gitlab_http_router_rule_total`                                                | Counter   |  17.4 | `rule_action`, `rule_type`                                              | Counts occurrences of HTTP Router rule's `rule_action` and `rule_type` |
| `gitlab_issuable_fast_count_by_state_failures_total`                           | Counter   |  13.5 |                                                                         | Number of soft-failed row count operations on the **Issue** and **Merge request** pages |
| `gitlab_issuable_fast_count_by_state_total`                                    | Counter   |  13.5 |                                                                         | Total number of row count operations on the **Issue** and **Merge request** pages |
| `gitlab_keeparound_refs_created_total`                                         | Counter   | 16.10 | `source`                                                                | Counts the number of keep-around refs actually created |
| `gitlab_keeparound_refs_requested_total`                                       | Counter   | 16.10 | `source`                                                                | Counts the number of keep-around refs requested to be created |
| `gitlab_memwd_violations_handled_total`                                        | Counter   |  15.9 |                                                                         | Total number of times Ruby process memory violations were handled |
| `gitlab_memwd_violations_total`                                                | Counter   |  15.9 |                                                                         | Total number of times a Ruby process violated a memory threshold |
| `gitlab_method_call_duration_seconds`                                          | Histogram |  10.2 | `controller`, `action`, `module`, `method`                              | Method calls real duration |
| `gitlab_omniauth_login_total`                                                  | Counter   |  16.1 | `omniauth_provider`, `status`                                           | Total number of OmniAuth logins attempts |
| `gitlab_page_out_of_bounds`                                                    | Counter   |  12.8 | `controller`, `action`, `bot`                                           | Counter for the PageLimiter pagination limit being hit |
| `gitlab_presentable_object_cacheless_render_real_duration_seconds`             | Histogram |  15.3 | `controller`, `action`, `endpoint_id`                                   | Duration of real time spent caching and representing specific web request objects |
| `gitlab_rack_attack_events_total`                                              | Counter   |  17.6 | `event_type`, `event_name`                                              | Counts the total number of events handled by Rack Attack. |
| `gitlab_rack_attack_throttle_limit`                                            | Gauge     |  17.6 | `event_name`                                                            | Reports the maximum number of requests that a client can make before Rack Attack throttles them. |
| `gitlab_rack_attack_throttle_period_seconds`                                   | Gauge     |  17.6 | `event_name`                                                            | Reports the duration over which requests for a client are counted before Rack Attack throttles them. |
| `gitlab_rails_boot_time_seconds`                                               | Gauge     |  14.8 |                                                                         | Time elapsed for Rails primary process to finish startup |
| `gitlab_rails_queue_duration_seconds`                                          | Histogram |   9.4 |                                                                         | Measures latency between GitLab Workhorse forwarding a request to Rails |
| `gitlab_ruby_threads_max_expected_threads`                                     | Gauge     |  13.3 |                                                                         | Maximum number of threads expected to be running and performing application work |
| `gitlab_ruby_threads_running_threads`                                          | Gauge     |  13.3 |                                                                         | Number of running Ruby threads by name |
| `gitlab_security_policies_policy_creation_duration_seconds`                    | Histogram |  17.6 |                                                                         | The amount of time to create policy-related configuration |
| `gitlab_security_policies_policy_deletion_duration_seconds`                    | Histogram |  17.6 |                                                                         | The amount of time to delete policy-related configuration |
| `gitlab_security_policies_policy_sync_duration_seconds`                        | Histogram |  17.6 |                                                                         | The amount of time to sync policy changes for a policy configuration |
| `gitlab_security_policies_scan_execution_configuration_rendering_seconds`      | Histogram |  17.3 |                                                                         | The amount of time to render scan execution policy CI configurations |
| `gitlab_security_policies_scan_result_process_duration_seconds`                | Histogram |  16.7 |                                                                         | The amount of time to process merge request approval policies |
| `gitlab_security_policies_sync_opened_merge_requests_duration_seconds`         | Histogram |  17.6 |                                                                         | The amount of time to sync opened merge requests after policy changes |
| `gitlab_security_policies_update_configuration_duration_seconds`               | Histogram |  17.6 |                                                                         | The amount of time to schedule sync for a policy configuration change |
| `gitlab_sli_rails_request_apdex_success_total`                                 | Counter   |  14.4 | `endpoint_id`, `feature_category`, `request_urgency`                    | Total number of successful requests that met the target duration for their urgency. Divide by `gitlab_sli_rails_requests_apdex_total` to get a success ratio |
| `gitlab_sli_rails_request_apdex_total`                                         | Counter   |  14.4 | `endpoint_id`, `feature_category`, `request_urgency`                    | Total number of request Apdex measurements. |
| `gitlab_sli_rails_request_error_total`                                         | Counter   |  15.7 | `endpoint_id`, `feature_category`, `request_urgency`, `error`           | Total number of request error measurements. |
| `gitlab_snowplow_events_total`                                                 | Counter   |  14.1 |                                                                         | Total number of GitLab Snowplow Analytics Instrumentation events emitted |
| `gitlab_snowplow_failed_events_total`                                          | Counter   |  14.1 |                                                                         | Total number of GitLab Snowplow Analytics Instrumentation events emission failures |
| `gitlab_snowplow_successful_events_total`                                      | Counter   |  14.1 |                                                                         | Total number of GitLab Snowplow Analytics Instrumentation events emission successes |
| `gitlab_spamcheck_request_duration_seconds`                                    | Histogram | 13.12 |                                                                         | The duration for requests between Rails and the anti-spam engine |
| `gitlab_sql_<role>_duration_seconds`                                           | Histogram | 13.10 |                                                                         | SQL execution time, excluding `SCHEMA` operations and `BEGIN` / `COMMIT`, grouped by database roles (primary/replica) |
| `gitlab_sql_duration_seconds`                                                  | Histogram |  10.2 |                                                                         | SQL execution time, excluding `SCHEMA` operations and `BEGIN` / `COMMIT` |
| `gitlab_transaction_cache_<key>_count_total`                                   | Counter   |  10.2 |                                                                         | Counter for total Rails cache calls (per key) |
| `gitlab_transaction_cache_<key>_duration_total`                                | Counter   |  10.2 |                                                                         | Counter for total time (seconds) spent in Rails cache calls (per key) |
| `gitlab_transaction_cache_count_total`                                         | Counter   |  10.2 |                                                                         | Counter for total Rails cache calls (aggregate) |
| `gitlab_transaction_cache_duration_total`                                      | Counter   |  10.2 |                                                                         | Counter for total time (seconds) spent in Rails cache calls (aggregate) |
| `gitlab_transaction_cache_read_hit_count_total`                                | Counter   |  10.2 | `controller`, `action`, `store`, `endpoint_id`                          | Counter for cache hits for Rails cache calls |
| `gitlab_transaction_cache_read_miss_count_total`                               | Counter   |  10.2 | `controller`, `action`, `store`, `endpoint_id`                          | Counter for cache misses for Rails cache calls |
| `gitlab_transaction_db_<role>_cached_count_total`                              | Counter   |  13.1 | `controller`, `action`, `endpoint_id`                                   | Counter for total number of cached SQL calls, grouped by database roles (primary/replica) |
| `gitlab_transaction_db_<role>_count_total`                                     | Counter   | 13.10 | `controller`, `action`, `endpoint_id`                                   | Counter for total number of SQL calls, grouped by database roles (primary/replica) |
| `gitlab_transaction_db_<role>_wal_cached_count_total`                          | Counter   |  14.1 | `controller`, `action`, `endpoint_id`                                   | Counter for total number of cached WAL (write ahead log location) queries, grouped by database roles (primary/replica) |
| `gitlab_transaction_db_<role>_wal_count_total`                                 | Counter   |  14.0 | `controller`, `action`, `endpoint_id`                                   | Counter for total number of WAL (write ahead log location) queries, grouped by database roles (primary/replica) |
| `gitlab_transaction_db_cached_count_total`                                     | Counter   |  13.1 | `controller`, `action`, `endpoint_id`                                   | Counter for total number of cached SQL calls |
| `gitlab_transaction_db_count_total`                                            | Counter   |  13.1 | `controller`, `action`, `endpoint_id`                                   | Counter for total number of SQL calls |
| `gitlab_transaction_db_write_count_total`                                      | Counter   |  13.1 | `controller`, `action`, `endpoint_id`                                   | Counter for total number of write SQL calls |
| `gitlab_transaction_duration_seconds`                                          | Histogram |  10.2 | `controller`, `action`, `endpoint_id`                                   | Duration for successful requests (`gitlab_transaction_*` metrics) |
| `gitlab_transaction_event_build_found_total`                                   | Counter   |   9.4 |                                                                         | Counter for build found for API /jobs/request |
| `gitlab_transaction_event_build_invalid_total`                                 | Counter   |   9.4 |                                                                         | Counter for build invalid due to concurrency conflict for API /jobs/request |
| `gitlab_transaction_event_build_not_found_cached_total`                        | Counter   |   9.4 |                                                                         | Counter for cached response of build not found for API /jobs/request |
| `gitlab_transaction_event_build_not_found_total`                               | Counter   |   9.4 |                                                                         | Counter for build not found for API /jobs/request |
| `gitlab_transaction_event_change_default_branch_total`                         | Counter   |   9.4 |                                                                         | Counter when default branch is changed for any repository |
| `gitlab_transaction_event_create_repository_total`                             | Counter   |   9.4 |                                                                         | Counter when any repository is created |
| `gitlab_transaction_event_etag_caching_cache_hit_total`                        | Counter   |   9.4 | `endpoint`                                                              | Counter for ETag cache hit. |
| `gitlab_transaction_event_etag_caching_header_missing_total`                   | Counter   |   9.4 | `endpoint`                                                              | Counter for ETag cache miss - header missing |
| `gitlab_transaction_event_etag_caching_key_not_found_total`                    | Counter   |   9.4 | `endpoint`                                                              | Counter for ETag cache miss - key not found |
| `gitlab_transaction_event_etag_caching_middleware_used_total`                  | Counter   |   9.4 | `endpoint`                                                              | Counter for ETag middleware accessed |
| `gitlab_transaction_event_etag_caching_resource_changed_total`                 | Counter   |   9.4 | `endpoint`                                                              | Counter for ETag cache miss - resource changed |
| `gitlab_transaction_event_fork_repository_total`                               | Counter   |   9.4 |                                                                         | Counter for repository forks (RepositoryForkWorker). Only incremented when source repository exists |
| `gitlab_transaction_event_import_repository_total`                             | Counter   |   9.4 |                                                                         | Counter for repository imports (RepositoryImportWorker) |
| `gitlab_transaction_event_patch_hard_limit_bytes_hit_total`                    | Counter   |  13.9 |                                                                         | Counter for diff patch size limit hits |
| `gitlab_transaction_event_push_branch_total`                                   | Counter   |   9.4 |                                                                         | Counter for all branch pushes |
| `gitlab_transaction_event_rails_exception_total`                               | Counter   |   9.4 |                                                                         | Counter for number of rails exceptions |
| `gitlab_transaction_event_receive_email_total`                                 | Counter   |   9.4 | `handler`                                                               | Counter for received emails |
| `gitlab_transaction_event_remove_branch_total`                                 | Counter   |   9.4 |                                                                         | Counter when a branch is removed for any repository |
| `gitlab_transaction_event_remove_repository_total`                             | Counter   |   9.4 |                                                                         | Counter when a repository is removed |
| `gitlab_transaction_event_remove_tag_total`                                    | Counter   |   9.4 |                                                                         | Counter when a tag is remove for any repository |
| `gitlab_transaction_event_sidekiq_exception_total`                             | Counter   |   9.4 |                                                                         | Counter of Sidekiq exceptions |
| `gitlab_transaction_event_stuck_import_jobs_total`                             | Counter   |   9.4 | `projects_without_jid_count`, `projects_with_jid_count`                 | Count of stuck import jobs |
| `gitlab_transaction_event_update_build_total`                                  | Counter   |   9.4 |                                                                         | Counter for update build for API `/jobs/request/:id` |
| `gitlab_transaction_new_redis_connections_total`                               | Counter   |   9.4 |                                                                         | Counter for new Redis connections |
| `gitlab_transaction_rails_queue_duration_total`                                | Counter   |   9.4 | `controller`, `action`, `endpoint_id`                                   | Measures latency between GitLab Workhorse forwarding a request to Rails |
| `gitlab_transaction_view_duration_total`                                       | Counter   |   9.4 | `controller`, `action`, `view`, `endpoint_id`                           | Duration for views |
| `gitlab_view_rendering_duration_seconds`                                       | Histogram |  10.2 | `controller`, `action`, `view`, `endpoint_id`                           | Duration for views (histogram) |
| `gitlab_vulnerability_report_branch_comparison_cpu_duration_seconds`           | Histogram | 15.11 |                                                                         | CPU execution duration of vulnerability report on default branch SQL query |
| `gitlab_vulnerability_report_branch_comparison_real_duration_seconds`          | Histogram | 15.11 |                                                                         | Wall clock execution duration of vulnerability report on default branch SQL query |
| `http_elasticsearch_requests_duration_seconds`                                 | Histogram |  13.1 | `controller`, `action`, `endpoint_id`                                   | Elasticsearch requests duration during web transactions. Premium and Ultimate only. |
| `http_elasticsearch_requests_total`                                            | Counter   |  13.1 | `controller`, `action`, `endpoint_id`                                   | Elasticsearch requests count during web transactions. Premium and Ultimate only. |
| `http_request_duration_seconds`                                                | Histogram |   9.4 | `method`                                                                | HTTP response time from rack middleware for successful requests |
| `http_requests_total`                                                          | Counter   |   9.4 | `method`, `status`                                                      | Rack request count |
| `job_queue_duration_seconds`                                                   | Histogram |   9.5 |                                                                         | Request handling execution time |
| `job_register_attempts_failed_total`                                           | Counter   |   9.5 |                                                                         | Counts the times a runner fails to register a job |
| `job_register_attempts_total`                                                  | Counter   |   9.5 |                                                                         | Counts the times a runner tries to register a job |
| `pipeline_graph_link_calculation_duration_seconds`                             | Histogram |  13.9 |                                                                         | Total time spent calculating links, in seconds |
| `pipeline_graph_links_per_job_ratio`                                           | Histogram |  13.9 |                                                                         | Ratio of links to job per graph |
| `pipeline_graph_links_total`                                                   | Histogram |  13.9 |                                                                         | Number of links per graph |
| `pipelines_created_total`                                                      | Counter   |   9.4 | `source`, `partition_id`                                                | Counter of pipelines created |
| `rack_uncaught_errors_total`                                                   | Counter   |   9.4 |                                                                         | Rack connections handling uncaught errors count |
| `redis_cache_generation_duration_seconds`                                      | Histogram |  15.6 | `cache_hit`, `cache_identifier`, `feature_category`, `backing_resource` | Time to generate Redis cache |
| `redis_hit_miss_operations_total`                                              | Counter   |  15.6 | `cache_hit`, `cache_identifier`, `feature_category`, `backing_resource` | Total number of Redis cache hits and misses |
| `search_advanced_boolean_settings`                                             | Gauge     |  17.3 | `name`                                                                  | Current state of Advanced search boolean settings |
| `search_advanced_index_repair_total`                                           | Counter   |  17.3 | `document_type`                                                         | Counts the number of index repair operations |
| `service_desk_new_note_email`                                                  | Counter   |  14.0 |                                                                         | Total number of email notifications on new Service Desk comment |
| `service_desk_thank_you_email`                                                 | Counter   |  14.0 |                                                                         | Total number of email responses to new Service Desk emails |
| `successful_login_captcha_total`                                               | Gauge     |  11.0 |                                                                         | Counter of successful CAPTCHA attempts during login |
| `upload_file_does_not_exist`                                                   | Counter   |  10.7 |                                                                         | Number of times an upload record could not find its file. |
| `user_session_logins_total`                                                    | Counter   |   9.4 |                                                                         | Counter of how many users have logged in since GitLab was started or restarted |
| `validity_check_network_errors_total`                                          | Counter   |  18.6 | `partner`, `error_class`                                                | Total network errors during partner token verification API calls. Ultimate only. |
| `validity_check_partner_api_duration_seconds`                                  | Histogram |  18.6 | `partner`                                                               | Partner API response time in seconds for token verification requests. Ultimate only. |
| `validity_check_partner_api_requests_total`                                    | Counter   |  18.6 | `partner`, `status`, `error_type`                                       | Total partner API verification requests with success/failure status. Ultimate only. |
| `validity_check_rate_limit_hits_total`                                         | Counter   |  18.6 | `limit_type`                                              | Total rate limit hits during partner token verification. Ultimate only. |

## Metrics controlled by a feature flag

The following metrics can be controlled by feature flags:

| Metric                                       | Feature flag |
|:---------------------------------------------|:-------------|
| `gitlab_view_rendering_duration_seconds`     | `prometheus_metrics_view_instrumentation` |
| `gitlab_ci_queue_depth_total`                | `gitlab_ci_builds_queuing_metrics` |
| `gitlab_ci_queue_size`                       | `gitlab_ci_builds_queuing_metrics` |
| `gitlab_ci_queue_size_total`                 | `gitlab_ci_builds_queuing_metrics` |
| `gitlab_ci_queue_iteration_duration_seconds` | `gitlab_ci_builds_queuing_metrics` |
| `gitlab_ci_current_queue_size`               | `gitlab_ci_builds_queuing_metrics` |
| `gitlab_ci_queue_retrieval_duration_seconds` | `gitlab_ci_builds_queuing_metrics` |
| `gitlab_ci_queue_active_runners_total`       | `gitlab_ci_builds_queuing_metrics` |

## Praefect metrics

You can [configure Praefect](../../gitaly/praefect/configure.md#praefect) to report metrics. For information
on available metrics, see [Monitoring Gitaly Cluster (Praefect)](../../gitaly/praefect/monitoring.md).

## Sidekiq metrics

Sidekiq jobs may also gather metrics, and these metrics can be accessed if the
Sidekiq exporter is enabled: for example, using the `monitoring.sidekiq_exporter`
configuration option in `gitlab.yml`. These metrics are served from the
`/metrics` path on the configured port.

| Metric                                                   | Type      | Since | Labels                                                                                    | Description |
|:---------------------------------------------------------|:----------|:------|:------------------------------------------------------------------------------------------|:------------|
| `destroyed_job_artifacts_count_total`                    | Counter   | 13.6  |                                                                                           | Number of destroyed expired job artifacts |
| `destroyed_pipeline_artifacts_count_total`               | Counter   | 13.8  |                                                                                           | Number of destroyed expired pipeline artifacts |
| `geo_ci_secure_files_checksum_failed`                    | Gauge     | 15.3  | `url`                                                                                     | Number of secure files failed to calculate the checksum on primary |
| `geo_ci_secure_files_checksum_total`                     | Gauge     | 15.3  | `url`                                                                                     | Number of secure files to checksum on primary |
| `geo_ci_secure_files_checksummed`                        | Gauge     | 15.3  | `url`                                                                                     | Number of secure files that successfully calculated the checksum on primary |
| `geo_ci_secure_files_failed`                             | Gauge     | 15.3  | `url`                                                                                     | Number of syncable secure files failed to sync on secondary |
| `geo_ci_secure_files_registry`                           | Gauge     | 15.3  | `url`                                                                                     | Number of secure files in the registry |
| `geo_ci_secure_files_synced`                             | Gauge     | 15.3  | `url`                                                                                     | Number of syncable secure files synced on secondary |
| `geo_ci_secure_files_verification_failed`                | Gauge     | 15.3  | `url`                                                                                     | Number of secure files that failed verification on secondary |
| `geo_ci_secure_files_verification_total`                 | Gauge     | 15.3  | `url`                                                                                     | Number of secure files to attempt to verify on secondary |
| `geo_ci_secure_files_verified`                           | Gauge     | 15.3  | `url`                                                                                     | Number of secure files successfully verified on secondary |
| `geo_ci_secure_files`                                    | Gauge     | 15.3  | `url`                                                                                     | Number of secure files on primary |
| `geo_container_repositories_checksum_failed`             | Gauge     | 15.10 | `url`                                                                                     | Number of container repositories failed to calculate the checksum on primary |
| `geo_container_repositories_checksum_total`              | Gauge     | 15.10 | `url`                                                                                     | Number of container repositories checksummed successfully on primary |
| `geo_container_repositories_checksummed`                 | Gauge     | 15.10 | `url`                                                                                     | Number of container repositories tried to checksum on primary |
| `geo_container_repositories_failed`                      | Gauge     | 15.4  | `url`                                                                                     | Number of syncable container repositories failed to sync on secondary |
| `geo_container_repositories_registry`                    | Gauge     | 15.4  | `url`                                                                                     | Number of container repositories in the registry |
| `geo_container_repositories_synced`                      | Gauge     | 15.4  | `url`                                                                                     | Number of container repositories synced on secondary |
| `geo_container_repositories_verification_failed`         | Gauge     | 15.10 | `url`                                                                                     | Number of container repositories' failed verifications on secondary |
| `geo_container_repositories_verification_total`          | Gauge     | 15.10 | `url`                                                                                     | Number of container repositories' verifications tried on secondary |
| `geo_container_repositories_verified`                    | Gauge     | 15.10 | `url`                                                                                     | Number of container repositories verified on secondary |
| `geo_container_repositories`                             | Gauge     | 15.4  | `url`                                                                                     | Number of container repositories on primary |
| `geo_cursor_last_event_id`                               | Gauge     | 10.2  | `url`                                                                                     | Last database ID of the event log processed by the secondary |
| `geo_cursor_last_event_timestamp`                        | Gauge     | 10.2  | `url`                                                                                     | Last UNIX timestamp of the event log processed by the secondary |
| `geo_db_replication_lag_seconds`                         | Gauge     | 10.2  | `url`                                                                                     | Database replication lag (seconds) |
| `geo_dependency_proxy_blob_checksum_failed`              | Gauge     | 15.6  |                                                                                           | Number of dependency proxy blobs failed to calculate the checksum on primary |
| `geo_dependency_proxy_blob_checksum_total`               | Gauge     | 15.6  |                                                                                           | Number of dependency proxy blobs to checksum on primary |
| `geo_dependency_proxy_blob_checksummed`                  | Gauge     | 15.6  |                                                                                           | Number of dependency proxy blobs that successfully calculated the checksum on primary |
| `geo_dependency_proxy_blob_failed`                       | Gauge     | 15.6  |                                                                                           | Number of dependency proxy blobs failed to sync on secondary |
| `geo_dependency_proxy_blob_registry`                     | Gauge     | 15.6  |                                                                                           | Number of dependency proxy blobs in the registry |
| `geo_dependency_proxy_blob_synced`                       | Gauge     | 15.6  |                                                                                           | Number of dependency proxy blobs synced on secondary |
| `geo_dependency_proxy_blob_verification_failed`          | Gauge     | 15.6  |                                                                                           | Number of dependency proxy blobs that failed verification on secondary |
| `geo_dependency_proxy_blob_verification_total`           | Gauge     | 15.6  |                                                                                           | Number of dependency proxy blobs to attempt to verify on secondary |
| `geo_dependency_proxy_blob_verified`                     | Gauge     | 15.6  |                                                                                           | Number of dependency proxy blobs successfully verified on secondary |
| `geo_dependency_proxy_blob`                              | Gauge     | 15.6  |                                                                                           | Number of dependency proxy blobs on primary |
| `geo_dependency_proxy_manifests_checksum_failed`         | Gauge     | 15.6  | `url`                                                                                     | Number of dependency proxy manifests failed to calculate the checksum on primary |
| `geo_dependency_proxy_manifests_checksum_total`          | Gauge     | 15.6  | `url`                                                                                     | Number of dependency proxy manifests to checksum on primary |
| `geo_dependency_proxy_manifests_checksummed`             | Gauge     | 15.6  | `url`                                                                                     | Number of dependency proxy manifests that successfully calculated the checksum on primary |
| `geo_dependency_proxy_manifests_failed`                  | Gauge     | 15.6  | `url`                                                                                     | Number of syncable dependency proxy manifests failed to sync on secondary |
| `geo_dependency_proxy_manifests_registry`                | Gauge     | 15.6  | `url`                                                                                     | Number of dependency proxy manifests in the registry |
| `geo_dependency_proxy_manifests_synced`                  | Gauge     | 15.6  | `url`                                                                                     | Number of syncable dependency proxy manifests synced on secondary |
| `geo_dependency_proxy_manifests_verification_failed`     | Gauge     | 15.6  | `url`                                                                                     | Number of dependency proxy manifests that failed verification on secondary |
| `geo_dependency_proxy_manifests_verification_total`      | Gauge     | 15.6  | `url`                                                                                     | Number of dependency proxy manifests to attempt to verify on secondary |
| `geo_dependency_proxy_manifests_verified`                | Gauge     | 15.6  | `url`                                                                                     | Number of dependency proxy manifests successfully verified on secondary |
| `geo_dependency_proxy_manifests`                         | Gauge     | 15.6  | `url`                                                                                     | Number of dependency proxy manifests on primary |
| `geo_design_management_repositories_checksum_failed`     | Gauge     | 16.1  | `url`                                                                                     | Number of design repositories failed to calculate the checksum on primary |
| `geo_design_management_repositories_checksum_total`      | Gauge     | 16.1  | `url`                                                                                     | Number of design repositories tried to checksum on primary |
| `geo_design_management_repositories_checksummed`         | Gauge     | 16.1  | `url`                                                                                     | Number of design repositories successfully checksummed on primary |
| `geo_design_management_repositories_failed`              | Gauge     | 16.1  | `url`                                                                                     | Number of syncable design repositories failed to sync on secondary |
| `geo_design_management_repositories_registry`            | Gauge     | 16.1  | `url`                                                                                     | Number of design repositories in the registry |
| `geo_design_management_repositories_synced`              | Gauge     | 16.1  | `url`                                                                                     | Number of syncable design repositories synced on secondary |
| `geo_design_management_repositories_verification_failed` | Gauge     | 16.1  | `url`                                                                                     | Number of design repositories verifications failed on secondary |
| `geo_design_management_repositories_verification_total`  | Gauge     | 16.1  | `url`                                                                                     | Number of design repositories verifications tried on secondary |
| `geo_design_management_repositories_verified`            | Gauge     | 16.1  | `url`                                                                                     | Number of design repositories verified on secondary |
| `geo_design_management_repositories`                     | Gauge     | 16.1  | `url`                                                                                     | Number of design repositories on primary |
| `geo_group_wiki_repositories_checksum_failed`            | Gauge     | 13.10 | `url`                                                                                     | Number of group wikis that failed to calculate the checksum on primary |
| `geo_group_wiki_repositories_checksum_total`             | Gauge     | 16.3  | `url`                                                                                     | Number of group wikis to checksum on primary |
| `geo_group_wiki_repositories_checksummed`                | Gauge     | 13.10 | `url`                                                                                     | Number of group wikis that successfully calculated the checksum on primary |
| `geo_group_wiki_repositories_failed`                     | Gauge     | 13.10 | `url`                                                                                     | Number of syncable group wikis failed to sync on secondary |
| `geo_group_wiki_repositories_registry`                   | Gauge     | 13.10 | `url`                                                                                     | Number of group wikis in the registry |
| `geo_group_wiki_repositories_synced`                     | Gauge     | 13.10 | `url`                                                                                     | Number of syncable group wikis synced on secondary |
| `geo_group_wiki_repositories_verification_failed`        | Gauge     | 16.3  | `url`                                                                                     | Number of group wikis that failed verification on secondary |
| `geo_group_wiki_repositories_verification_total`         | Gauge     | 16.3  | `url`                                                                                     | Number of group wikis to attempt to verify on secondary |
| `geo_group_wiki_repositories_verified`                   | Gauge     | 16.3  | `url`                                                                                     | Number of group wikis successfully verified on secondary |
| `geo_group_wiki_repositories`                            | Gauge     | 13.10 | `url`                                                                                     | Number of group wikis on primary |
| `geo_job_artifacts_checksum_failed`                      | Gauge     | 14.8  | `url`                                                                                     | Number of job artifacts failed to calculate the checksum on primary |
| `geo_job_artifacts_checksum_total`                       | Gauge     | 14.8  | `url`                                                                                     | Number of job artifacts to checksum on primary |
| `geo_job_artifacts_checksummed`                          | Gauge     | 14.8  | `url`                                                                                     | Number of job artifacts that successfully calculated the checksum on primary |
| `geo_job_artifacts_failed`                               | Gauge     | 14.8  | `url`                                                                                     | Number of syncable job artifacts failed to sync on secondary |
| `geo_job_artifacts_registry`                             | Gauge     | 14.8  | `url`                                                                                     | Number of job artifacts in the registry |
| `geo_job_artifacts_synced`                               | Gauge     | 14.8  | `url`                                                                                     | Number of syncable job artifacts synced on secondary |
| `geo_job_artifacts_verification_failed`                  | Gauge     | 14.8  | `url`                                                                                     | Number of job artifacts that failed verification on secondary |
| `geo_job_artifacts_verification_total`                   | Gauge     | 14.8  | `url`                                                                                     | Number of job artifacts to attempt to verify on secondary |
| `geo_job_artifacts_verified`                             | Gauge     | 14.8  | `url`                                                                                     | Number of job artifacts successfully verified on secondary |
| `geo_job_artifacts`                                      | Gauge     | 14.8  | `url`                                                                                     | Number of job artifacts on primary |
| `geo_last_event_id`                                      | Gauge     | 10.2  | `url`                                                                                     | Database ID of the latest event log entry on the primary |
| `geo_last_event_timestamp`                               | Gauge     | 10.2  | `url`                                                                                     | UNIX timestamp of the latest event log entry on the primary |
| `geo_last_successful_status_check_timestamp`             | Gauge     | 10.2  | `url`                                                                                     | Last timestamp when the status was successfully updated |
| `geo_lfs_objects_checksum_failed`                        | Gauge     | 14.6  | `url`                                                                                     | Number of LFS objects failed to calculate the checksum on primary |
| `geo_lfs_objects_checksum_total`                         | Gauge     | 14.6  | `url`                                                                                     | Number of LFS objects that need to be checksummed on primary |
| `geo_lfs_objects_checksummed`                            | Gauge     | 14.6  | `url`                                                                                     | Number of LFS objects checksummed successfully on primary |
| `geo_lfs_objects_failed`                                 | Gauge     | 10.2  | `url`                                                                                     | Number of syncable LFS objects failed to sync on secondary |
| `geo_lfs_objects_registry`                               | Gauge     | 14.6  | `url`                                                                                     | Number of LFS objects in the registry |
| `geo_lfs_objects_synced`                                 | Gauge     | 10.2  | `url`                                                                                     | Number of syncable LFS objects synced on secondary |
| `geo_lfs_objects_verification_failed`                    | Gauge     | 14.6  | `url`                                                                                     | Number of LFS objects that failed verifications on secondary |
| `geo_lfs_objects_verification_total`                     | Gauge     | 14.6  | `url`                                                                                     | Number of LFS objects to attempt to verify on secondary |
| `geo_lfs_objects_verified`                               | Gauge     | 14.6  | `url`                                                                                     | Number of LFS objects successfully verified on secondary |
| `geo_lfs_objects`                                        | Gauge     | 10.2  | `url`                                                                                     | Number of LFS objects on primary |
| `geo_merge_request_diffs_checksum_failed`                | Gauge     | 13.4  | `url`                                                                                     | Number of merge request diffs failed to calculate the checksum on primary |
| `geo_merge_request_diffs_checksum_total`                 | Gauge     | 13.12 | `url`                                                                                     | Number of merge request diffs to checksum on primary |
| `geo_merge_request_diffs_checksummed`                    | Gauge     | 13.4  | `url`                                                                                     | Number of merge request diffs that successfully calculated the checksum on primary |
| `geo_merge_request_diffs_failed`                         | Gauge     | 13.4  | `url`                                                                                     | Number of syncable merge request diffs failed to sync on secondary |
| `geo_merge_request_diffs_registry`                       | Gauge     | 13.4  | `url`                                                                                     | Number of merge request diffs in the registry |
| `geo_merge_request_diffs_synced`                         | Gauge     | 13.4  | `url`                                                                                     | Number of syncable merge request diffs synced on secondary |
| `geo_merge_request_diffs_verification_failed`            | Gauge     | 13.12 | `url`                                                                                     | Number of merge request diffs that failed verification on secondary |
| `geo_merge_request_diffs_verification_total`             | Gauge     | 13.12 | `url`                                                                                     | Number of merge request diffs to attempt to verify on secondary |
| `geo_merge_request_diffs_verified`                       | Gauge     | 13.12 | `url`                                                                                     | Number of merge request diffs successfully verified on secondary |
| `geo_merge_request_diffs`                                | Gauge     | 13.4  | `url`                                                                                     | Number of merge request diffs on primary |
| `geo_package_files_checksum_failed`                      | Gauge     | 13.0  | `url`                                                                                     | Number of package files failed to calculate the checksum on primary |
| `geo_package_files_checksummed`                          | Gauge     | 13.0  | `url`                                                                                     | Number of package files checksummed on primary |
| `geo_package_files_failed`                               | Gauge     | 13.3  | `url`                                                                                     | Number of syncable package files failed to sync on secondary |
| `geo_package_files_registry`                             | Gauge     | 13.3  | `url`                                                                                     | Number of package files in the registry |
| `geo_package_files_synced`                               | Gauge     | 13.3  | `url`                                                                                     | Number of syncable package files synced on secondary |
| `geo_package_files`                                      | Gauge     | 13.0  | `url`                                                                                     | Number of package files on primary |
| `geo_packages_nuget_symbols`                             | Gauge     | 18.6  | `url`                                                                                     | Number of Nuget symbol files on primary |
| `geo_packages_nuget_symbols_checksum_total`              | Gauge     | 18.6  | `url`                                                                                     | Number of Nuget symbol files to checksum on primary |
| `geo_packages_nuget_symbols_checksummed`                 | Gauge     | 18.6  | `url`                                                                                     | Number of Nuget symbol files that successfully calculated the checksum on primary |
| `geo_packages_nuget_symbols_checksum_failed`             | Gauge     | 18.6  | `url`                                                                                     | Number of Nuget symbol files that failed to calculate the checksum on primary |
| `geo_packages_nuget_symbols_synced`                      | Gauge     | 18.6  | `url`                                                                                     | Number of syncable Nuget symbol files synced on secondary |
| `geo_packages_nuget_symbols_failed`                      | Gauge     | 18.6  | `url`                                                                                     | Number of syncable Nuget symbol files failed to sync on secondary |
| `geo_packages_nuget_symbols_registry`                    | Gauge     | 18.6  | `url`                                                                                     | Number of Nuget symbol files in the registry |
| `geo_packages_nuget_symbols_verification_total`          | Gauge     | 18.6  | `url`                                                                                     | Number of Nuget symbol files to attempt to verify on secondary |
| `geo_packages_nuget_symbols_verified`                    | Gauge     | 18.6  | `url`                                                                                     | Number of Nuget symbol files successfully verified on secondary |
| `geo_packages_nuget_symbols_verification_failed`         | Gauge     | 18.6  | `url`                                                                                     | Number of Nuget symbol files that failed verification on secondary |
| `geo_pages_deployments_checksum_failed`                  | Gauge     | 14.6  | `url`                                                                                     | Number of pages deployments failed to calculate the checksum on primary |
| `geo_pages_deployments_checksum_total`                   | Gauge     | 14.6  | `url`                                                                                     | Number of pages deployments to checksum on primary |
| `geo_pages_deployments_checksummed`                      | Gauge     | 14.6  | `url`                                                                                     | Number of pages deployments that successfully calculated the checksum on primary |
| `geo_pages_deployments_failed`                           | Gauge     | 14.3  | `url`                                                                                     | Number of syncable pages deployments failed to sync on secondary |
| `geo_pages_deployments_registry`                         | Gauge     | 14.3  | `url`                                                                                     | Number of pages deployments in the registry |
| `geo_pages_deployments_synced`                           | Gauge     | 14.3  | `url`                                                                                     | Number of syncable pages deployments synced on secondary |
| `geo_pages_deployments_verification_failed`              | Gauge     | 14.6  | `url`                                                                                     | Number of pages deployments verifications failed on secondary |
| `geo_pages_deployments_verification_total`               | Gauge     | 14.6  | `url`                                                                                     | Number of pages deployments to attempt to verify on secondary |
| `geo_pages_deployments_verified`                         | Gauge     | 14.6  | `url`                                                                                     | Number of pages deployments successfully verified on secondary |
| `geo_pages_deployments`                                  | Gauge     | 14.3  | `url`                                                                                     | Number of pages deployments on primary |
| `geo_project_repositories_checksum_failed`               | Gauge     | 16.2  | `url`                                                                                     | Number of Project Repositories that failed to calculate the checksum on primary |
| `geo_project_repositories_checksum_total`                | Gauge     | 16.2  | `url`                                                                                     | Number of Project Repositories to checksum on primary |
| `geo_project_repositories_checksummed`                   | Gauge     | 16.2  | `url`                                                                                     | Number of Project Repositories that successfully calculated the checksum on primary |
| `geo_project_repositories_failed`                        | Gauge     | 16.2  | `url`                                                                                     | Number of syncable Project Repositories failed to sync on secondary |
| `geo_project_repositories_registry`                      | Gauge     | 16.2  | `url`                                                                                     | Number of Project Repositories in the registry |
| `geo_project_repositories_synced`                        | Gauge     | 16.2  | `url`                                                                                     | Number of syncable Project Repositories synced on secondary |
| `geo_project_repositories_verification_failed`           | Gauge     | 16.2  | `url`                                                                                     | Number of Project Repositories that failed verification on secondary |
| `geo_project_repositories_verification_total`            | Gauge     | 16.2  | `url`                                                                                     | Number of Project Repositories to attempt to verify on secondary |
| `geo_project_repositories_verified`                      | Gauge     | 16.2  | `url`                                                                                     | Number of Project Repositories successfully verified on secondary |
| `geo_project_repositories`                               | Gauge     | 16.2  | `url`                                                                                     | Number of Project Repositories on primary |
| `geo_project_wiki_repositories_checksum_failed`          | Gauge     | 15.10 | `url`                                                                                     | Number of Project Wiki Repositories that failed to calculate the checksum on primary |
| `geo_project_wiki_repositories_checksum_total`           | Gauge     | 15.10 | `url`                                                                                     | Number of Project Wiki Repositories to checksum on primary |
| `geo_project_wiki_repositories_checksummed`              | Gauge     | 15.10 | `url`                                                                                     | Number of Project Wiki Repositories that successfully calculated the checksum on primary |
| `geo_project_wiki_repositories_failed`                   | Gauge     | 15.10 | `url`                                                                                     | Number of syncable Project Wiki Repositories failed to sync on secondary |
| `geo_project_wiki_repositories_registry`                 | Gauge     | 15.10 | `url`                                                                                     | Number of Project Wiki Repositories in the registry |
| `geo_project_wiki_repositories_synced`                   | Gauge     | 15.10 | `url`                                                                                     | Number of syncable Project Wiki Repositories synced on secondary |
| `geo_project_wiki_repositories_verification_failed`      | Gauge     | 15.10 | `url`                                                                                     | Number of Project Wiki Repositories that failed verification on secondary |
| `geo_project_wiki_repositories_verification_total`       | Gauge     | 15.10 | `url`                                                                                     | Number of Project Wiki Repositories to attempt to verify on secondary |
| `geo_project_wiki_repositories_verified`                 | Gauge     | 15.10 | `url`                                                                                     | Number of Project Wiki Repositories successfully verified on secondary |
| `geo_project_wiki_repositories`                          | Gauge     | 15.10 | `url`                                                                                     | Number of Project Wiki Repositories on primary |
| `geo_repositories_checksum_failed`                       | Gauge     | 10.7  | `url`                                                                                     | Deprecated for removal in 17.0. Missing in 16.3 and 16.4. Replaced by `geo_project_repositories_checksum_failed`. Number of repositories failed to calculate the checksum on primary |
| `geo_repositories_checksummed`                           | Gauge     | 10.7  | `url`                                                                                     | Deprecated for removal in 17.0. Missing in 16.3 and 16.4. Replaced by `geo_project_repositories_checksummed`. Number of repositories checksummed on primary |
| `geo_repositories_failed`                                | Gauge     | 10.2  | `url`                                                                                     | Deprecated for removal in 17.0. Missing in 16.3 and 16.4. Replaced by `geo_project_repositories_failed`. Number of repositories failed to sync on secondary |
| `geo_repositories_synced`                                | Gauge     | 10.2  | `url`                                                                                     | Deprecated for removal in 17.0. Missing in 16.3 and 16.4. Replaced by `geo_project_repositories_synced`. Number of repositories synced on secondary |
| `geo_repositories_verification_failed`                   | Gauge     | 10.7  | `url`                                                                                     | Deprecated for removal in 17.0. Missing in 16.3 and 16.4. Replaced by `geo_project_repositories_verification_failed`. Number of repositories that failed verification on secondary |
| `geo_repositories_verified`                              | Gauge     | 10.7  | `url`                                                                                     | Deprecated for removal in 17.0. Missing in 16.3 and 16.4. Replaced by `geo_project_repositories_verified`. Number of repositories successfully verified on secondary |
| `geo_repositories`                                       | Gauge     | 10.2  | `url`                                                                                     | Deprecated in 17.9. The future GitLab release for removal is yet to be confirmed. Use `geo_project_repositories` instead. Total number of repositories available on primary |
| `geo_snippet_repositories_checksum_failed`               | Gauge     | 13.4  | `url`                                                                                     | Number of snippets failed to calculate the checksum on primary |
| `geo_snippet_repositories_checksummed`                   | Gauge     | 13.4  | `url`                                                                                     | Number of snippets checksummed on primary |
| `geo_snippet_repositories_failed`                        | Gauge     | 13.4  | `url`                                                                                     | Number of syncable snippets failed on secondary |
| `geo_snippet_repositories_registry`                      | Gauge     | 13.4  | `url`                                                                                     | Number of syncable snippets in the registry |
| `geo_snippet_repositories_synced`                        | Gauge     | 13.4  | `url`                                                                                     | Number of syncable snippets synced on secondary |
| `geo_snippet_repositories`                               | Gauge     | 13.4  | `url`                                                                                     | Number of snippets on primary |
| `geo_status_failed_total`                                | Counter   | 10.2  | `url`                                                                                     | Number of times retrieving the status from the Geo Node failed |
| `geo_terraform_state_versions_checksum_failed`           | Gauge     | 13.5  | `url`                                                                                     | Number of terraform state versions failed to calculate the checksum on primary |
| `geo_terraform_state_versions_checksum_total`            | Gauge     | 13.12 | `url`                                                                                     | Number of terraform state versions that need to be checksummed on primary |
| `geo_terraform_state_versions_checksummed`               | Gauge     | 13.5  | `url`                                                                                     | Number of terraform state versions checksummed successfully on primary |
| `geo_terraform_state_versions_failed`                    | Gauge     | 13.5  | `url`                                                                                     | Number of syncable terraform state versions failed to sync on secondary |
| `geo_terraform_state_versions_registry`                  | Gauge     | 13.5  | `url`                                                                                     | Number of terraform state versions in the registry |
| `geo_terraform_state_versions_synced`                    | Gauge     | 13.5  | `url`                                                                                     | Number of syncable terraform state versions synced on secondary |
| `geo_terraform_state_versions_verification_failed`       | Gauge     | 13.12 | `url`                                                                                     | Number of terraform state versions that failed verification on secondary |
| `geo_terraform_state_versions_verification_total`        | Gauge     | 13.12 | `url`                                                                                     | Number of terraform state versions to attempt to verify on secondary |
| `geo_terraform_state_versions_verified`                  | Gauge     | 13.12 | `url`                                                                                     | Number of terraform state versions successfully verified on secondary |
| `geo_terraform_state_versions`                           | Gauge     | 13.5  | `url`                                                                                     | Number of terraform state versions on primary |
| `geo_uploads_checksum_failed`                            | Gauge     | 14.6  | `url`                                                                                     | Number of uploads failed to calculate the checksum on primary |
| `geo_uploads_checksum_total`                             | Gauge     | 14.6  | `url`                                                                                     | Number of uploads to checksum on primary |
| `geo_uploads_checksummed`                                | Gauge     | 14.6  | `url`                                                                                     | Number of uploads that successfully calculated the checksum on primary |
| `geo_uploads_failed`                                     | Gauge     | 14.1  | `url`                                                                                     | Number of syncable uploads failed to sync on secondary |
| `geo_uploads_registry`                                   | Gauge     | 14.1  | `url`                                                                                     | Number of uploads in the registry |
| `geo_uploads_synced`                                     | Gauge     | 14.1  | `url`                                                                                     | Number of uploads synced on secondary |
| `geo_uploads_verification_failed`                        | Gauge     | 14.6  | `url`                                                                                     | Number of uploads that failed verification on secondary |
| `geo_uploads_verification_total`                         | Gauge     | 14.6  | `url`                                                                                     | Number of uploads to attempt to verify on secondary |
| `geo_uploads_verified`                                   | Gauge     | 14.6  | `url`                                                                                     | Number of uploads successfully verified on secondary |
| `geo_uploads`                                            | Gauge     | 14.1  | `url`                                                                                     | Number of uploads on primary |
| `gitlab_ci_queue_active_runners_total`                   | Histogram | 16.3  |                                                                                           | The number of active runners that can process the CI/CD queue in a project |
| `gitlab_maintenance_mode`                                | Gauge     | 15.11 |                                                                                           | Is GitLab Maintenance Mode enabled? |
| `gitlab_memwd_violations_handled_total`                  | Counter   | 15.9  |                                                                                           | Total number of times Sidekiq process memory violations were handled |
| `gitlab_memwd_violations_total`                          | Counter   | 15.9  |                                                                                           | Total number of times a Sidekiq process violated a memory threshold |
| `gitlab_optimistic_locking_retries`                      | Histogram | 13.10 |                                                                                           | Number of retry attempts to execute optimistic retry lock |
| `gitlab_transaction_event_remote_mirrors_failed_total`   | Counter   | 10.8  |                                                                                           | Counter for failed remote mirrors |
| `gitlab_transaction_event_remote_mirrors_finished_total` | Counter   | 10.8  |                                                                                           | Counter for finished remote mirrors |
| `gitlab_transaction_event_remote_mirrors_running_total`  | Counter   | 10.8  |                                                                                           | Counter for running remote mirrors |
| `global_search_awaiting_indexing_queue_size`             | Gauge     | 13.2  |                                                                                           | Deprecated and planned for removal in 18.0. Replaced by `search_advanced_awaiting_indexing_queue_size`. Number of database updates waiting to be synchronized to Elasticsearch while indexing is paused |
| `global_search_bulk_cron_initial_queue_size`             | Gauge     | 13.1  |                                                                                           | Deprecated and planned for removal in 18.0. Replaced by `search_advanced_bulk_cron_initial_queue_size`. Number of initial database updates waiting to be synchronized to Elasticsearch |
| `global_search_bulk_cron_queue_size`                     | Gauge     | 12.10 |                                                                                           | Deprecated and planned for removal in 18.0. Replaced by `search_advanced_bulk_cron_queue_size`. Number of incremental database updates waiting to be synchronized to Elasticsearch |
| `limited_capacity_worker_max_running_jobs`               | Gauge     | 13.5  | `worker`                                                                                  | Maximum number of running jobs |
| `limited_capacity_worker_remaining_work_count`           | Gauge     | 13.5  | `worker`                                                                                  | Number of jobs waiting to be enqueued |
| `limited_capacity_worker_running_jobs`                   | Gauge     | 13.5  | `worker`                                                                                  | Number of running jobs |
| `search_advanced_awaiting_indexing_queue_size`           | Gauge     | 17.6  |                                                                                           | Number of database updates waiting to be synchronized to Elasticsearch while indexing is paused |
| `search_advanced_bulk_cron_embedding_queue_size`         | Gauge     | 17.6  |                                                                                           | Number of embedding updates waiting to be synchronized to Elasticsearch |
| `search_advanced_bulk_cron_initial_queue_size`           | Gauge     | 17.6  |                                                                                           | Number of initial database updates waiting to be synchronized to Elasticsearch |
| `search_advanced_bulk_cron_queue_size`                   | Gauge     | 17.6  |                                                                                           | Number of incremental database updates waiting to be synchronized to Elasticsearch |
| `sidekiq_concurrency_limit_current_concurrent_jobs`      | Gauge     | 17.6  | `worker`, `feature_category`                                                              | Current number of concurrent running jobs. |
| `sidekiq_concurrency_limit_current_limit`                | Gauge     | 18.3  | `worker`, `feature_category`                                                              | Number of concurrent jobs currently allowed to run subject to throttling |
| `sidekiq_concurrency_limit_max_concurrent_jobs`          | Gauge     | 17.3  | `worker`, `feature_category`                                                              | Max number of concurrent running Sidekiq jobs |
| `sidekiq_concurrency_limit_queue_jobs`                   | Gauge     | 17.3  | `worker`, `feature_category`                                                              | Number of Sidekiq jobs waiting in the concurrency limit queue |
| `sidekiq_concurrency`                                    | Gauge     | 12.5  |                                                                                           | Maximum number of Sidekiq jobs |
| `sidekiq_elasticsearch_requests_duration_seconds`        | Histogram | 13.1  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` | Duration in seconds that a Sidekiq job spent in requests to an Elasticsearch server |
| `sidekiq_elasticsearch_requests_total`                   | Counter   | 13.1  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` | Elasticsearch requests during a Sidekiq job execution |
| `sidekiq_jobs_completion_seconds`                        | Histogram | 12.2  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` | Seconds to complete Sidekiq job |
| `sidekiq_jobs_cpu_seconds`                               | Histogram | 12.4  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` | Seconds of CPU time to run Sidekiq job |
| `sidekiq_jobs_db_seconds`                                | Histogram | 12.9  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` | Seconds of DB time to run Sidekiq job |
| `sidekiq_jobs_dead_total`                                | Counter   | 13.7  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `urgency`               | Sidekiq dead jobs (jobs that have run out of retries) |
| `sidekiq_jobs_failed_total`                              | Counter   | 12.2  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `urgency`               | Sidekiq jobs failed |
| `sidekiq_jobs_gitaly_seconds`                            | Histogram | 12.9  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` | Seconds of Gitaly time to run Sidekiq job |
| `sidekiq_jobs_interrupted_total`                         | Counter   | 15.2  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `urgency`               | Sidekiq jobs interrupted |
| `sidekiq_jobs_queue_duration_seconds`                    | Histogram | 12.5  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `urgency`               | Duration in seconds that a Sidekiq job was queued before being executed |
| `sidekiq_jobs_retried_total`                             | Counter   | 12.2  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `urgency`               | Sidekiq jobs retried |
| `sidekiq_jobs_skipped_total`                             | Counter   | 16.2  | `worker`, `action`, `feature_category`, `reason`                                          | Number of jobs being skipped (dropped or deferred) when `drop_sidekiq_jobs` feature flag is enabled or `run_sidekiq_jobs` feature flag is disabled |
| `sidekiq_mem_total_bytes`                                | Gauge     | 15.3  |                                                                                           | Number of bytes allocated for both objects consuming an object slot and objects that required a malloc' |
| `sidekiq_redis_requests_duration_seconds`                | Histogram | 13.1  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` | Duration in seconds that a Sidekiq job spent querying a Redis server |
| `sidekiq_redis_requests_total`                           | Counter   | 13.1  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` | Redis requests during a Sidekiq job execution |
| `sidekiq_running_jobs`                                   | Gauge     | 12.2  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `urgency`               | Number of Sidekiq jobs running |
| `sidekiq_throttling_events_total`                        | Counter   | 18.3  | `worker`, `strategy`                                                                      | Total number of Sidekiq throttling events |
| `sidekiq_watchdog_running_jobs_total`                    | Counter   | 15.9  | `worker_class`                                                                            | Current running jobs when RSS limit was reached |

## Database load balancing metrics

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

The following metrics are available:

| Metric                                                  | Type    | Since                                                       | Labels   | Description |
|:--------------------------------------------------------|:--------|:------------------------------------------------------------|:---------|:------------|
| `db_load_balancing_hosts`                               | Gauge   | [12.3](https://gitlab.com/gitlab-org/gitlab/-/issues/13630) |          | Current number of load balancing hosts |
| `sidekiq_load_balancing_count`                          | Counter | 13.11                                                       | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency`, `data_consistency`, `load_balancing_strategy` | Sidekiq jobs using load balancing with data consistency set to `:sticky` or `:delayed` |
| `gitlab_transaction_caught_up_replica_pick_count_total` | Counter | 14.1                                                        | `result` | Number of search attempts for caught up replica |

## Database partitioning metrics

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

The following metrics are available:

| Metric                  | Type  | Since                                                        | Description |
|:------------------------|:------|:-------------------------------------------------------------|:------------|
| `db_partitions_present` | Gauge | [13.4](https://gitlab.com/gitlab-org/gitlab/-/issues/227353) | Number of database partitions present |
| `db_partitions_missing` | Gauge | [13.4](https://gitlab.com/gitlab-org/gitlab/-/issues/227353) | Number of database partitions currently expected, but not present |

## Connection pool metrics

These metrics record the status of the database
[connection pools](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/ConnectionPool.html),
and the metrics all have these labels:

- `class` - the Ruby class being recorded.
  - `ActiveRecord::Base` is the main database connection.
  - `Geo::TrackingBase` is the connection to the Geo tracking database, if
    enabled.
- `host` - the host name used to connect to the database.
- `port` - the port used to connect to the database.

| Metric                                        | Type  | Since | Description |
|:----------------------------------------------|:------|:------|:------------|
| `gitlab_database_connection_pool_size`        | Gauge | 13.0  | Total connection pool capacity |
| `gitlab_database_connection_pool_connections` | Gauge | 13.0  | Current connections in the pool |
| `gitlab_database_connection_pool_busy`        | Gauge | 13.0  | Connections in use where the owner is still alive |
| `gitlab_database_connection_pool_dead`        | Gauge | 13.0  | Connections in use where the owner is not alive |
| `gitlab_database_connection_pool_idle`        | Gauge | 13.0  | Connections not in use |
| `gitlab_database_connection_pool_waiting`     | Gauge | 13.0  | Threads currently waiting on this queue |

## Ruby metrics

Some basic Ruby runtime metrics are available:

| Metric                                    | Type    | Since | Description |
|:------------------------------------------|:--------|:------|:------------|
| `ruby_gc_duration_seconds`                | Counter | 11.1  | Time spent by Ruby in GC |
| `ruby_gc_stat_...`                        | Gauge   | 11.1  | Various metrics from [GC.stat](https://ruby-doc.org/core-2.6.5/GC.html#method-c-stat) |
| `ruby_gc_stat_ext_heap_fragmentation`     | Gauge   | 15.2  | Degree of Ruby heap fragmentation as live objects versus eden slots (range 0 to 1) |
| `ruby_file_descriptors`                   | Gauge   | 11.1  | File descriptors per process |
| `ruby_sampler_duration_seconds`           | Counter | 11.1  | Time spent collecting stats |
| `ruby_process_cpu_seconds_total`          | Gauge   | 12.0  | Total amount of CPU time per process |
| `ruby_process_max_fds`                    | Gauge   | 12.0  | Maximum number of open file descriptors per process |
| `ruby_process_resident_memory_bytes`      | Gauge   | 12.0  | Memory usage by process (RSS/Resident Set Size) |
| `ruby_process_resident_anon_memory_bytes` | Gauge   | 15.6  | Anonymous memory usage by process (RSS/Resident Set Size) |
| `ruby_process_resident_file_memory_bytes` | Gauge   | 15.6  | File-backed memory usage by process (RSS/Resident Set Size) |
| `ruby_process_unique_memory_bytes`        | Gauge   | 13.0  | Memory usage by process (USS/Unique Set Size) |
| `ruby_process_proportional_memory_bytes`  | Gauge   | 13.0  | Memory usage by process (PSS/Proportional Set Size) |
| `ruby_process_start_time_seconds`         | Gauge   | 12.0  | UNIX timestamp of process start time |

## Puma Metrics

| Metric                    | Type  | Since | Description |
|:--------------------------|:------|:------|:------------|
| `puma_workers`            | Gauge | 12.0  | Total number of workers |
| `puma_running_workers`    | Gauge | 12.0  | Number of booted workers |
| `puma_stale_workers`      | Gauge | 12.0  | Number of old workers |
| `puma_running`            | Gauge | 12.0  | Number of running threads |
| `puma_queued_connections` | Gauge | 12.0  | Number of connections in that worker's "to do" set waiting for a worker thread |
| `puma_active_connections` | Gauge | 12.0  | Number of threads processing a request |
| `puma_pool_capacity`      | Gauge | 12.0  | Number of requests the worker is capable of taking right now |
| `puma_max_threads`        | Gauge | 12.0  | Maximum number of worker threads |
| `puma_idle_threads`       | Gauge | 12.0  | Number of spawned threads which are not processing a request |

## Redis metrics

These client metrics are meant to complement Redis server metrics.
These metrics are broken down per
[Redis instance](https://docs.gitlab.com/omnibus/settings/redis.html#running-with-multiple-redis-instances).
These metrics all have a `storage` label which indicates the Redis
instance. For example, `cache` or `shared_state`.

| Metric                                            | Type      | Since | Description |
|:--------------------------------------------------|:----------|:------|:------------|
| `gitlab_redis_client_exceptions_total`            | Counter   | 13.2  | Number of Redis client exceptions, broken down by exception class |
| `gitlab_redis_client_requests_total`              | Counter   | 13.2  | Number of Redis client requests |
| `gitlab_redis_client_requests_duration_seconds`   | Histogram | 13.2  | Redis request latency, excluding blocking commands |
| `gitlab_redis_client_redirections_total`          | Counter   | 15.10 | Number of Redis Cluster MOVED/ASK redirections, broken down by redirection type |
| `gitlab_redis_client_requests_pipelined_commands` | Histogram | 16.4  | Number of commands per pipeline sent to a single Redis server |
| `gitlab_redis_client_pipeline_redirections_count` | Histogram | 17.0  | Number of Redis Cluster redirections in a pipeline |

## Git LFS metrics

Metrics to track various [Git LFS](https://git-lfs.com/) functionality.

| Metric                                             | Type    | Since | Description |
|:---------------------------------------------------|:--------|:------|:------------|
| `gitlab_sli_lfs_update_objects_total`              | Counter | 16.10 | Number of updated LFS objects in total |
| `gitlab_sli_lfs_update_objects_error_total`        | Counter | 16.10 | Number of updated LFS object errors in total |
| `gitlab_sli_lfs_check_objects_total`               | Counter | 16.10 | Number of check LFS objects in total |
| `gitlab_sli_lfs_check_objects_error_total`         | Counter | 16.10 | Number of check LFS object errors in total |
| `gitlab_sli_lfs_validate_link_objects_total`       | Counter | 16.10 | Number of validated LFS linked objects in total |
| `gitlab_sli_lfs_validate_link_objects_error_total` | Counter | 16.10 | Number of validated LFS linked object errors in total |

## Secret Detection Partner Token verification metrics

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208292) in GitLab 18.6.

{{< /history >}}

Metrics to track Secret Detection partner token verification with external partner APIs (AWS, GCP, Postman, etc.).

| Metric                                            | Type      | Since | Labels                                        | Description |
|:--------------------------------------------------|:----------|:------|:----------------------------------------------|:------------|
| `validity_check_partner_api_duration_seconds`     | Histogram | 18.6  | `partner`                                     | Tracks API response time for partner token verification requests. Histogram buckets: [0.1, 0.25, 0.5, 1, 2, 5, 10] seconds. |
| `validity_check_partner_api_requests_total`       | Counter   | 18.6  | `partner`, `status`, `error_type`             | Total number of partner API verification requests. `status` can be `success` or `failure`. `error_type` is included only for failures (e.g., `network_error`, `rate_limit`, `response_error`). |
| `validity_check_network_errors_total`             | Counter   | 18.6  | `partner`, `error_class`                      | Total network errors during partner API calls. `error_class` indicates the type of error (e.g., `Timeout`, `ConnectionRefused`, `HTTPError`). |
| `validity_check_rate_limit_hits_total`            | Counter   | 18.6  | `limit_type`                    | Total rate limit hits during token verification. `limit_type` corresponds to the partner rate limit key (e.g., `partner_aws_api`, `partner_gcp_api`, `partner_postman_api`). |

### Partner labels

The `partner` label can have the following values:

- `aws` - Amazon Web Services tokens
- `gcp` - Google Cloud Platform tokens
- `postman` - Postman API tokens

## Metrics shared directory

The GitLab Prometheus client requires a directory to store metrics data shared between multi-process services.
Those files are shared among all instances running under Puma server.
The directory must be accessible to all running Puma's processes, or
metrics can't function correctly.

This directory's location is configured using environment variable `prometheus_multiproc_dir`.
For best performance, create this directory in `tmpfs`.

If GitLab is installed using the [Linux package](https://docs.gitlab.com/omnibus/)
and `tmpfs` is available, then GitLab configures the metrics directory for you.
