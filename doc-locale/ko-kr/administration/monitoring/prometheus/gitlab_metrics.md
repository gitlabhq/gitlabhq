---
stage: Shared responsibility based on functional area
group: Shared responsibility based on functional area
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Prometheus 측정항목
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab Prometheus 측정항목을 활성화하려면:

1. 관리자 액세스 권한이 있는 사용자로 GitLab에 로그인합니다.
1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **측정항목 및 프로파일링**을 선택합니다.
1. **측정항목 - Prometheus** 섹션을 찾고 **GitLab Prometheus 측정항목 엔드포인트 활성화**를 선택합니다.
1. [GitLab 다시 시작](../../restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용합니다.

자체 컴파일된 설치의 경우 직접 구성해야 합니다.

## 측정항목 수집 {#collecting-the-metrics}

GitLab은 자체 내부 서비스 측정항목을 모니터링하고 `/-/metrics` 엔드포인트에서 사용 가능하게 합니다. 다른 [Prometheus](https://prometheus.io) 익스포터와 달리 측정항목에 액세스하려면 클라이언트 IP 주소가 [명시적으로 허용](../ip_allowlist.md)되어야 합니다.

이러한 측정항목은 [Linux 패키지](https://docs.gitlab.com/omnibus/) 및 Helm 차트 설치에 대해 활성화되고 수집됩니다. 자체 컴파일된 설치의 경우 이러한 측정항목을 수동으로 활성화하고 Prometheus 서버에서 수집해야 합니다.

Sidekiq 노드에서 측정항목을 활성화하고 보는 방법은 [Sidekiq 측정항목](#sidekiq-metrics)을 참조하세요.

## 사용 가능한 측정항목 {#metrics-available}

{{< history >}}

- `caller_id` [제거됨](https://gitlab.com/gitlab-org/gitlab/-/issues/392622) - `redis_hit_miss_operations_total` 및 `redis_cache_generation_duration_seconds`에서 GitLab 15.11로 제거되었습니다.

{{< /history >}}

다음 측정항목을 사용할 수 있습니다:

| 측정항목                                                                         | 유형      | 이후 | 레이블                                                                  | 설명 |
|:-------------------------------------------------------------------------------|:----------|------:|:------------------------------------------------------------------------|:------------|
| `action_cable_active_connections`                                              | 게이지     |  13.4 | `server_mode`                                                           | 현재 연결된 ActionCable WS 클라이언트 수 |
| `action_cable_broadcasts_total`                                                | 카운터   | 13.10 | `server_mode`                                                           | 전송된 ActionCable 브로드캐스트 수 |
| `action_cable_pool_current_size`                                               | 게이지     |  13.4 | `server_mode`                                                           | ActionCable 스레드 풀의 현재 작업자 스레드 수 |
| `action_cable_pool_largest_size`                                               | 게이지     |  13.4 | `server_mode`                                                           | ActionCable 스레드 풀에서 지금까지 관찰된 가장 큰 작업자 스레드 수 |
| `action_cable_pool_max_size`                                                   | 게이지     |  13.4 | `server_mode`                                                           | ActionCable 스레드 풀의 최대 작업자 스레드 수 |
| `action_cable_pool_min_size`                                                   | 게이지     |  13.4 | `server_mode`                                                           | ActionCable 스레드 풀의 최소 작업자 스레드 수 |
| `action_cable_pool_pending_tasks`                                              | 게이지     |  13.4 | `server_mode`                                                           | ActionCable 스레드 풀에서 실행을 기다리는 작업 수 |
| `action_cable_pool_tasks_total`                                                | 게이지     |  13.4 | `server_mode`                                                           | ActionCable 스레드 풀에서 실행된 총 작업 수 |
| `action_cable_single_client_transmissions_total`                               | 카운터   | 13.10 | `server_mode`                                                           | 모든 채널의 모든 클라이언트로 전송된 ActionCable 메시지 수 |
| `action_cable_subscription_confirmations_total`                                | 카운터   | 13.10 | `server_mode`                                                           | 클라이언트에서 확인된 ActionCable 구독 수 |
| `action_cable_subscription_rejections_total`                                   | 카운터   | 13.10 | `server_mode`                                                           | 클라이언트에서 거부된 ActionCable 구독 수 |
| `action_cable_transmitted_bytes_total`                                         | 카운터   |  16.0 | `operation`, `channel`                                                  | ActionCable을 통해 전송된 총 바이트 수 |
| `active_context_queue_size`                                                    | 게이지     | 18.7  | `queue_name`, `shard`                                                   | 각 ActiveContext 큐의 항목 수 |
| `artifact_report_<report_type>_builds_completed_total`                         | 카운터   |  15.3 |                                                                         | 완료된 CI 빌드의 카운터(보고서 유형 아티팩트 포함, 보고서 유형별로 그룹화되고 상태로 레이블 지정됨) |
| `auto_devops_pipelines_completed_total`                                        | 카운터   |  12.7 |                                                                         | 완료된 Auto DevOps 파이프라인의 카운터(상태로 레이블 지정됨) |
| `cached_object_operations_total`                                               | 카운터   |  15.3 | `controller`, `action`, `endpoint_id`                                   | 특정 웹 요청에 대해 캐시된 총 개체 수 |
| `ci_report_parser_duration_seconds`                                            | 히스토그램 |  13.9 | `parser`                                                                | CI/CD 보고서 아티팩트를 구문 분석하는 시간 |
| `dependency_linker_usage`                                                      | 카운터   |  16.8 | `used_on`                                                               | 종속성 링커가 사용된 횟수 |
| `email_receiver_error`                                                         | 카운터   |  14.1 |                                                                         | 들어오는 이메일 처리 시 오류의 총 수 |
| `failed_login_captcha_total`                                                   | 게이지     |  11.0 |                                                                         | 로그인 중 실패한 CAPTCHA 시도의 카운터 |
| `gitlab_application_rate_limiter_throttle_utilization_ratio`                   | 히스토그램 |  17.6 | `throttle_key`, `peek`, `feature_category`                              | GitLab 애플리케이션 속도 제한기의 스로틀 사용률 비율입니다. |
| `gitaly_circuit_breaker_requests_total`                                        | 카운터   |  18.9 | `circuit_state`, `result`, `reason`                                     | 회로 차단기로 처리된 총 Gitaly 요청입니다. `result`은(는) `allowed`, `rejected` 또는 `error`일 수 있습니다. `reason`은(는) 오류 세부 정보를 제공합니다(예: `resource_exhausted`). |
| `gitaly_circuit_breaker_transitions_total`                                     | 카운터   |  18.9 | `from_state`, `to_state`                                                | 총 회로 차단기 상태 전환입니다. 상태는 `closed`, `open`입니다. 구조화된 로그에서 자세한 엔드포인트 및 스토리지 정보를 사용할 수 있습니다. |
| `gitlab_cache_misses_total`                                                    | 카운터   |  10.2 | `controller`, `action`, `store`, `endpoint_id`                          | 캐시 읽기 누락 |
| `gitlab_cache_operation_duration_seconds`                                      | 히스토그램 |  10.2 | `operation`, `store`, `endpoint_id`                                     | 캐시 액세스 시간 |
| `gitlab_cache_operations_total`                                                | 카운터   |  12.2 | `controller`, `action`, `operation`, `store`, `endpoint_id`             | 컨트롤러 또는 작업별 캐시 작업 |
| `gitlab_cache_read_multikey_count`                                             | 히스토그램 |  15.7 | `controller`, `action`, `store`, `endpoint_id`                          | 다중 키 캐시 읽기 작업에서 키의 개수 |
| `gitlab_ci_active_jobs`                                                        | 히스토그램 |  14.2 |                                                                         | 파이프라인이 생성될 때 활성 작업의 수 |
| `gitlab_ci_build_trace_errors_total`                                           | 카운터   |  14.4 | `error_reason`                                                          | 빌드 추적에서 다양한 오류 유형의 총 수 |
| `gitlab_ci_current_queue_size`                                                 | 게이지     |  16.3 |                                                                         | 초기화된 CI/CD 빌드 큐의 현재 크기 |
| `gitlab_ci_job_token_authorization_failures`                                   | 카운터   | 17.11 | `same_root_ancestor`                                                    | CI JOB 토큰을 통한 실패한 인증 시도의 수 |
| `gitlab_ci_job_token_inbound_access`                                           | 카운터   |  17.2 |                                                                         | CI 작업 토큰을 통한 인바운드 액세스 수 |
| `gitlab_ci_pipeline_builder_scoped_variables_duration`                         | 히스토그램 |  14.5 |                                                                         | CI/CD 작업에 대한 범위 지정 변수를 만드는 데 걸리는 시간(초) |
| `gitlab_ci_pipeline_creation_duration_seconds`                                 | 히스토그램 |  13.0 | `gitlab`                                                                | CI/CD 파이프라인을 만드는 데 걸리는 시간(초) |
| `gitlab_ci_pipeline_security_orchestration_policy_processing_duration_seconds` | 히스토그램 | 13.12 |                                                                         | CI/CD 파이프라인에서 보안 정책을 처리하는 데 걸리는 시간(초) |
| `gitlab_ci_pipeline_size_builds`                                               | 히스토그램 |  13.1 | `source`                                                                | 파이프라인 원본별로 그룹화된 파이프라인 내의 빌드 총 수 |
| `gitlab_ci_queue_depth_total`                                                  | 히스토그램 |  16.3 |                                                                         | 작업 결과와 관련된 CI/CD 빌드 큐의 크기 |
| `gitlab_ci_queue_iteration_duration_seconds`                                   | 히스토그램 |  16.3 |                                                                         | CI/CD 큐에서 빌드를 찾는 데 걸리는 시간 |
| `gitlab_ci_queue_operations_total`                                             | 카운터   |  16.3 |                                                                         | 큐 내에서 발생하는 모든 작업을 계산합니다. |
| `gitlab_ci_queue_retrieval_duration_seconds`                                   | 히스토그램 |  16.3 |                                                                         | 빌드 큐를 검색하는 SQL 쿼리를 실행하는 데 걸리는 시간 |
| `gitlab_ci_queue_size_total`                                                   | 히스토그램 |  16.3 |                                                                         | 초기화된 CI/CD 빌드 큐의 크기 |
| `gitlab_ci_runner_authentication_failure_total`                                | 카운터   |  15.2 |                                                                         | 러너 인증이 실패한 총 횟수 |
| `gitlab_ci_runner_authentication_success_total`                                | 카운터   |  15.2 | `type`                                                                  | 러너 인증이 성공한 총 횟수 |
| `gitlab_ci_trace_bytes_total`                                                  | 카운터   |  13.4 |                                                                         | 전송된 빌드 추적 바이트의 총 양 |
| `gitlab_ci_trace_finalize_duration_seconds`                                    | 히스토그램 |  13.6 |                                                                         | 빌드 추적 청크를 개체 스토리지로 마이그레이션하는 기간 |
| `gitlab_ci_trace_operations_total`                                             | 카운터   |  13.4 | `operation`                                                             | 빌드 추적에서 다양한 작업의 총 양 |
| `gitlab_connection_pool_available_count`                                       | 게이지     |  16.7 |                                                                         | 풀에서 사용 가능한 연결 수 |
| `gitlab_connection_pool_size`                                                  | 게이지     |  16.7 |                                                                         | 연결 풀의 크기 |
| `gitlab_database_transaction_seconds`                                          | 히스토그램 |  12.1 |                                                                         | 데이터베이스 트랜잭션에 소요된 시간(초) |
| `gitlab_dependency_paths_found_total`                                          | 카운터   |  18.3 | `cyclic`                                                                | 특정 종속성에 대해 발견된 상위 종속성 경로의 수를 계산합니다. |
| `gitlab_diffs_collection_real_duration_seconds`                                | 히스토그램 |  15.8 | `controller`, `action`, `endpoint_id`                                   | diffs 배치 요청에서 머지 리퀘스트 diff 파일을 쿼리하는 데 소요된 시간(초) |
| `gitlab_diffs_comparison_real_duration_seconds`                                | 히스토그램 |  15.8 | `controller`, `action`, `endpoint_id`                                   | diffs 배치 요청에서 비교 데이터를 가져오는 데 소요된 시간(초) |
| `gitlab_diffs_highlight_cache_decorate_real_duration_seconds`                  | 히스토그램 |  15.8 | `controller`, `action`, `endpoint_id`                                   | diffs 배치 요청에서 캐시로부터 강조 표시된 줄을 설정하는 데 소요된 시간(초) |
| `gitlab_diffs_render_real_duration_seconds`                                    | 히스토그램 |  15.8 | `controller`, `action`, `endpoint_id`                                   | diffs 배치 요청에서 diffs를 직렬화하고 렌더링하는 데 소요된 시간(초) |
| `gitlab_diffs_reorder_real_duration_seconds`                                   | 히스토그램 |  15.8 | `controller`, `action`, `endpoint_id`                                   | diffs 배치 요청에서 diff 파일 재정렬에 소요된 시간(초) |
| `gitlab_diffs_unfold_real_duration_seconds`                                    | 히스토그램 |  15.8 | `controller`, `action`, `endpoint_id`                                   | diffs 배치 요청에서 위치를 펼치는 데 소요된 시간(초) |
| `gitlab_diffs_unfoldable_positions_real_duration_seconds`                      | 히스토그램 |  15.8 | `controller`, `action`                                                  | diffs 배치 요청에서 펼칠 수 있는 메모 위치를 가져오는 데 소요된 시간(초) |
| `gitlab_diffs_write_cache_real_duration_seconds`                               | 히스토그램 |  15.8 | `controller`, `action`, `endpoint_id`                                   | diffs 배치 요청에서 강조 표시된 줄과 통계를 캐시하는 데 소요된 시간(초) |
| `gitlab_external_http_duration_seconds`                                        | 카운터   |  13.8 |                                                                         | 외부 시스템에 대한 각 HTTP 호출에 소요된 시간(초) |
| `gitlab_external_http_exception_total`                                         | 카운터   |  13.8 |                                                                         | 외부 HTTP 호출을 할 때 발생한 예외의 총 수 |
| `gitlab_external_http_total`                                                   | 카운터   |  13.8 | `controller`, `action`, `endpoint_id`                                   | 외부 시스템에 대한 HTTP 호출의 총 수 |
| `gitlab_find_dependency_paths_real_duration_seconds`                           | 히스토그램 |  18.3 |                                                                         | 주어진 구성요소에 대한 상위 종속성 경로를 해결하는 데 소요된 시간(초)입니다. |
| `gitlab_ghost_user_migration_lag_seconds`                                      | 게이지     |  15.6 |                                                                         | 고스트 사용자 마이그레이션을 위해 예약된 가장 오래된 레코드의 대기 시간(초) |
| `gitlab_ghost_user_migration_scheduled_records_total`                          | 게이지     |  15.6 |                                                                         | 예약된 고스트 사용자 마이그레이션의 총 수 |
| `gitlab_highlight_usage`                                                       | 카운터   |  16.8 | `used_on`                                                               | `Gitlab::Highlight`이(가) 사용된 횟수 |
| `gitlab_http_router_rule_total`                                                | 카운터   |  17.4 | `rule_action`, `rule_type`                                              | HTTP Router rule의 `rule_action` 및 `rule_type` 발생을 계산합니다. |
| `gitlab_issuable_fast_count_by_state_failures_total`                           | 카운터   |  13.5 |                                                                         | **이슈** 및 **머지 리퀘스트** 페이지에서 소프트 실패 행 개수 작업의 수 |
| `gitlab_issuable_fast_count_by_state_total`                                    | 카운터   |  13.5 |                                                                         | **이슈** 및 **머지 리퀘스트** 페이지에서 행 개수 작업의 총 수 |
| `gitlab_keeparound_refs_created_total`                                         | 카운터   | 16.10 | `source`                                                                | 실제로 생성된 키프 주위의 참조 수를 계산합니다. |
| `gitlab_keeparound_refs_requested_total`                                       | 카운터   | 16.10 | `source`                                                                | 생성을 요청한 키프 주위의 참조 수를 계산합니다. |
| `gitlab_memwd_violations_handled_total`                                        | 카운터   |  15.9 |                                                                         | Ruby 프로세스 메모리 위반이 처리된 총 횟수 |
| `gitlab_memwd_violations_total`                                                | 카운터   |  15.9 |                                                                         | Ruby 프로세스가 메모리 임계값을 위반한 총 횟수 |
| `gitlab_method_call_duration_seconds`                                          | 히스토그램 |  10.2 | `controller`, `action`, `module`, `method`                              | 메서드 호출 실제 기간 |
| `gitlab_omniauth_login_total`                                                  | 카운터   |  16.1 | `omniauth_provider`, `status`                                           | OmniAuth 로그인 시도의 총 수 |
| `gitlab_page_out_of_bounds`                                                    | 카운터   |  12.8 | `controller`, `action`, `bot`                                           | PageLimiter 페이지 나누기 제한이 초과된 경우의 카운터 |
| `gitlab_presentable_object_cacheless_render_real_duration_seconds`             | 히스토그램 |  15.3 | `controller`, `action`, `endpoint_id`                                   | 특정 웹 요청 개체를 캐시하고 표현하는 데 소요된 실제 시간의 기간 |
| `gitlab_rack_attack_events_total`                                              | 카운터   |  17.6 | `event_type`, `event_name`                                              | Rack Attack에서 처리한 총 이벤트 수를 계산합니다. |
| `gitlab_rack_attack_throttle_limit`                                            | 게이지     |  17.6 | `event_name`                                                            | Rack Attack이 클라이언트를 제한하기 전에 클라이언트가 할 수 있는 최대 요청 수를 보고합니다. |
| `gitlab_rack_attack_throttle_period_seconds`                                   | 게이지     |  17.6 | `event_name`                                                            | Rack Attack이 클라이언트를 제한하기 전에 클라이언트 요청을 계산하는 기간을 보고합니다. |
| `gitlab_rails_boot_time_seconds`                                               | 게이지     |  14.8 |                                                                         | Rails 기본 프로세스가 시작을 완료하는 데 걸린 시간 |
| `gitlab_rails_queue_duration_seconds`                                          | 히스토그램 |   9.4 |                                                                         | GitLab Workhorse에서 Rails로 요청을 전달할 때의 지연 시간을 측정합니다. |
| `gitlab_ruby_threads_max_expected_threads`                                     | 게이지     |  13.3 |                                                                         | 실행 중이고 애플리케이션 작업을 수행할 것으로 예상되는 최대 스레드 수 |
| `gitlab_ruby_threads_running_threads`                                          | 게이지     |  13.3 |                                                                         | 이름별 실행 중인 Ruby 스레드 수 |
| `gitlab_security_policies_policy_creation_duration_seconds`                    | 히스토그램 |  17.6 |                                                                         | 정책 관련 구성을 만드는 데 걸리는 시간 |
| `gitlab_security_policies_policy_deletion_duration_seconds`                    | 히스토그램 |  17.6 |                                                                         | 정책 관련 구성을 삭제하는 데 걸리는 시간 |
| `gitlab_security_policies_policy_sync_duration_seconds`                        | 히스토그램 |  17.6 |                                                                         | 정책 구성에 대한 정책 변경을 동기화하는 데 걸리는 시간 |
| `gitlab_security_policies_scan_execution_configuration_rendering_seconds`      | 히스토그램 |  17.3 |                                                                         | 검사 실행 정책 CI 구성을 렌더링하는 데 걸리는 시간 |
| `gitlab_security_policies_scan_result_process_duration_seconds`                | 히스토그램 |  16.7 |                                                                         | 머지 리퀘스트 승인 정책을 처리하는 데 걸리는 시간 |
| `gitlab_security_policies_sync_opened_merge_requests_duration_seconds`         | 히스토그램 |  17.6 |                                                                         | 정책 변경 후 열린 머지 리퀘스트를 동기화하는 데 걸리는 시간 |
| `gitlab_security_policies_update_configuration_duration_seconds`               | 히스토그램 |  17.6 |                                                                         | 정책 구성 변경에 대한 동기화를 예약하는 데 걸리는 시간 |
| `gitlab_sli_rails_request_apdex_success_total`                                 | 카운터   |  14.4 | `endpoint_id`, `feature_category`, `request_urgency`                    | 긴급성에 대한 대상 기간을 충족한 성공적인 요청의 총 수입니다. `gitlab_sli_rails_requests_apdex_total`로 나누어 성공 비율을 얻습니다. |
| `gitlab_sli_rails_request_apdex_total`                                         | 카운터   |  14.4 | `endpoint_id`, `feature_category`, `request_urgency`                    | 요청 Apdex 측정의 총 수입니다. |
| `gitlab_sli_rails_request_error_total`                                         | 카운터   |  15.7 | `endpoint_id`, `feature_category`, `request_urgency`, `error`           | 요청 오류 측정의 총 수입니다. |
| `gitlab_snowplow_events_total`                                                 | 카운터   |  14.1 |                                                                         | 내보낸 GitLab Snowplow Analytics Instrumentation 이벤트의 총 수 |
| `gitlab_snowplow_failed_events_total`                                          | 카운터   |  14.1 |                                                                         | GitLab Snowplow Analytics Instrumentation 이벤트 내보내기 실패의 총 수 |
| `gitlab_snowplow_successful_events_total`                                      | 카운터   |  14.1 |                                                                         | GitLab Snowplow Analytics Instrumentation 이벤트 내보내기 성공의 총 수 |
| `gitlab_spamcheck_request_duration_seconds`                                    | 히스토그램 | 13.12 |                                                                         | Rails와 스팸 방지 엔진 간 요청의 기간 |
| `gitlab_sql_<role>_duration_seconds`                                           | 히스토그램 | 13.10 |                                                                         | `SCHEMA` 작업 및 `BEGIN` / `COMMIT`을(를) 제외한 SQL 실행 시간, 데이터베이스 역할별로 그룹화됨(기본/복제본) |
| `gitlab_sql_duration_seconds`                                                  | 히스토그램 |  10.2 |                                                                         | `SCHEMA` 작업 및 `BEGIN` / `COMMIT`을(를) 제외한 SQL 실행 시간 |
| `gitlab_transaction_cache_<key>_count_total`                                   | 카운터   |  10.2 |                                                                         | 총 Rails 캐시 호출(키별)의 카운터 |
| `gitlab_transaction_cache_<key>_duration_total`                                | 카운터   |  10.2 |                                                                         | Rails 캐시 호출(키별)에 소요된 총 시간(초)의 카운터 |
| `gitlab_transaction_cache_count_total`                                         | 카운터   |  10.2 |                                                                         | 총 Rails 캐시 호출(집계)의 카운터 |
| `gitlab_transaction_cache_duration_total`                                      | 카운터   |  10.2 |                                                                         | Rails 캐시 호출(집계)에 소요된 총 시간(초)의 카운터 |
| `gitlab_transaction_cache_read_hit_count_total`                                | 카운터   |  10.2 | `controller`, `action`, `store`, `endpoint_id`                          | Rails 캐시 호출의 캐시 히트 카운터 |
| `gitlab_transaction_cache_read_miss_count_total`                               | 카운터   |  10.2 | `controller`, `action`, `store`, `endpoint_id`                          | Rails 캐시 호출의 캐시 누락 카운터 |
| `gitlab_transaction_db_<role>_cached_count_total`                              | 카운터   |  13.1 | `controller`, `action`, `endpoint_id`                                   | 캐시된 SQL 호출의 총 수에 대한 카운터(데이터베이스 역할별로 그룹화됨 - 기본/복제본) |
| `gitlab_transaction_db_<role>_count_total`                                     | 카운터   | 13.10 | `controller`, `action`, `endpoint_id`                                   | SQL 호출의 총 수에 대한 카운터(데이터베이스 역할별로 그룹화됨 - 기본/복제본) |
| `gitlab_transaction_db_<role>_wal_cached_count_total`                          | 카운터   |  14.1 | `controller`, `action`, `endpoint_id`                                   | 캐시된 WAL(쓰기 선행 로그 위치) 쿼리의 총 수에 대한 카운터(데이터베이스 역할별로 그룹화됨 - 기본/복제본) |
| `gitlab_transaction_db_<role>_wal_count_total`                                 | 카운터   |  14.0 | `controller`, `action`, `endpoint_id`                                   | WAL(쓰기 선행 로그 위치) 쿼리의 총 수에 대한 카운터(데이터베이스 역할별로 그룹화됨 - 기본/복제본) |
| `gitlab_transaction_db_cached_count_total`                                     | 카운터   |  13.1 | `controller`, `action`, `endpoint_id`                                   | 캐시된 SQL 호출의 총 수에 대한 카운터 |
| `gitlab_transaction_db_count_total`                                            | 카운터   |  13.1 | `controller`, `action`, `endpoint_id`                                   | SQL 호출의 총 수에 대한 카운터 |
| `gitlab_transaction_db_write_count_total`                                      | 카운터   |  13.1 | `controller`, `action`, `endpoint_id`                                   | 쓰기 SQL 호출의 총 수에 대한 카운터 |
| `gitlab_transaction_duration_seconds`                                          | 히스토그램 |  10.2 | `controller`, `action`, `endpoint_id`                                   | 성공적인 요청에 대한 기간(`gitlab_transaction_*` 측정항목) |
| `gitlab_transaction_event_build_found_total`                                   | 카운터   |   9.4 |                                                                         | API /jobs/request에서 발견된 빌드 카운터 |
| `gitlab_transaction_event_build_invalid_total`                                 | 카운터   |   9.4 |                                                                         | API /jobs/request에 대한 동시성 충돌로 인한 빌드 무효화 카운터 |
| `gitlab_transaction_event_build_not_found_cached_total`                        | 카운터   |   9.4 |                                                                         | API /jobs/request에서 발견되지 않은 빌드의 캐시된 응답 카운터 |
| `gitlab_transaction_event_build_not_found_total`                               | 카운터   |   9.4 |                                                                         | API /jobs/request에서 발견되지 않은 빌드 카운터 |
| `gitlab_transaction_event_change_default_branch_total`                         | 카운터   |   9.4 |                                                                         | 저장소의 기본 브랜치가 변경되었을 때 카운터 |
| `gitlab_transaction_event_create_repository_total`                             | 카운터   |   9.4 |                                                                         | 저장소가 생성되었을 때 카운터 |
| `gitlab_transaction_event_etag_caching_cache_hit_total`                        | 카운터   |   9.4 | `endpoint`                                                              | ETag 캐시 히트 카운터입니다. |
| `gitlab_transaction_event_etag_caching_header_missing_total`                   | 카운터   |   9.4 | `endpoint`                                                              | ETag 캐시 누락 - 헤더 누락 카운터 |
| `gitlab_transaction_event_etag_caching_key_not_found_total`                    | 카운터   |   9.4 | `endpoint`                                                              | ETag 캐시 누락 - 키를 찾을 수 없음 카운터 |
| `gitlab_transaction_event_etag_caching_middleware_used_total`                  | 카운터   |   9.4 | `endpoint`                                                              | ETag 미들웨어 액세스됨 카운터 |
| `gitlab_transaction_event_etag_caching_resource_changed_total`                 | 카운터   |   9.4 | `endpoint`                                                              | ETag 캐시 누락 - 리소스 변경됨 카운터 |
| `gitlab_transaction_event_fork_repository_total`                               | 카운터   |   9.4 |                                                                         | 저장소 포크(RepositoryForkWorker) 카운터입니다. 원본 저장소가 존재할 때만 증가 |
| `gitlab_transaction_event_import_repository_total`                             | 카운터   |   9.4 |                                                                         | 저장소 가져오기(RepositoryImportWorker) 카운터 |
| `gitlab_transaction_event_patch_hard_limit_bytes_hit_total`                    | 카운터   |  13.9 |                                                                         | diff 패치 크기 제한 히트 카운터 |
| `gitlab_transaction_event_push_branch_total`                                   | 카운터   |   9.4 |                                                                         | 모든 브랜치 푸시 카운터 |
| `gitlab_transaction_event_rails_exception_total`                               | 카운터   |   9.4 |                                                                         | Rails 예외 수 카운터 |
| `gitlab_transaction_event_remove_branch_total`                                 | 카운터   |   9.4 |                                                                         | 저장소의 브랜치가 제거되었을 때 카운터 |
| `gitlab_transaction_event_remove_repository_total`                             | 카운터   |   9.4 |                                                                         | 저장소가 제거되었을 때 카운터 |
| `gitlab_transaction_event_remove_tag_total`                                    | 카운터   |   9.4 |                                                                         | 태그가 저장소에서 제거되었을 때 카운터 |
| `gitlab_transaction_event_sidekiq_exception_total`                             | 카운터   |   9.4 |                                                                         | Sidekiq 예외의 카운터 |
| `gitlab_transaction_event_stuck_import_jobs_total`                             | 카운터   |   9.4 | `projects_without_jid_count`, `projects_with_jid_count`                 | 중단된 가져오기 작업의 수 |
| `gitlab_transaction_event_update_build_total`                                  | 카운터   |   9.4 |                                                                         | API `/jobs/request/:id`에 대한 빌드 업데이트 카운터 |
| `gitlab_transaction_new_redis_connections_total`                               | 카운터   |   9.4 |                                                                         | 새로운 Redis 연결 카운터 |
| `gitlab_transaction_rails_queue_duration_total`                                | 카운터   |   9.4 | `controller`, `action`, `endpoint_id`                                   | GitLab Workhorse에서 Rails로 요청을 전달할 때의 지연 시간을 측정합니다. |
| `gitlab_transaction_view_duration_total`                                       | 카운터   |   9.4 | `controller`, `action`, `view`, `endpoint_id`                           | 보기의 기간 |
| `gitlab_view_rendering_duration_seconds`                                       | 히스토그램 |  10.2 | `controller`, `action`, `view`, `endpoint_id`                           | 보기 기간(히스토그램) |
| `gitlab_vulnerability_report_branch_comparison_cpu_duration_seconds`           | 히스토그램 | 15.11 |                                                                         | 기본 브랜치 SQL 쿼리의 취약성 보고서의 CPU 실행 기간 |
| `gitlab_vulnerability_report_branch_comparison_real_duration_seconds`          | 히스토그램 | 15.11 |                                                                         | 기본 브랜치 SQL 쿼리의 취약성 보고서의 벽시계 실행 기간 |
| `http_elasticsearch_requests_duration_seconds`                                 | 히스토그램 |  13.1 | `controller`, `action`, `endpoint_id`                                   | 웹 트랜잭션 중 Elasticsearch 요청 기간입니다. Premium 및 Ultimate만 해당합니다. |
| `http_elasticsearch_requests_total`                                            | 카운터   |  13.1 | `controller`, `action`, `endpoint_id`                                   | 웹 트랜잭션 중 Elasticsearch 요청 수입니다. Premium 및 Ultimate만 해당합니다. |
| `http_request_duration_seconds`                                                | 히스토그램 |   9.4 | `method`                                                                | 성공한 요청에 대한 Rack 미들웨어의 HTTP 응답 시간 |
| `http_requests_total`                                                          | 카운터   |   9.4 | `method`, `status`                                                      | Rack 요청 수 |
| `job_queue_duration_seconds`                                                   | 히스토그램 |   9.5 |                                                                         | 요청 처리 실행 시간 |
| `job_register_attempts_failed_total`                                           | 카운터   |   9.5 |                                                                         | 러너가 작업을 등록하지 못한 횟수를 계산합니다 |
| `job_register_attempts_total`                                                  | 카운터   |   9.5 |                                                                         | 러너가 작업을 등록하려고 시도한 횟수를 계산합니다 |
| `pipeline_graph_link_calculation_duration_seconds`                             | 히스토그램 |  13.9 |                                                                         | 링크 계산에 소비한 총 시간(초) |
| `pipeline_graph_links_per_job_ratio`                                           | 히스토그램 |  13.9 |                                                                         | 그래프당 작업에 대한 링크의 비율 |
| `pipeline_graph_links_total`                                                   | 히스토그램 |  13.9 |                                                                         | 그래프당 링크 수 |
| `pipelines_created_total`                                                      | 카운터   |   9.4 | `source`, `partition_id`                                                | 생성된 파이프라인의 카운터 |
| `rack_uncaught_errors_total`                                                   | 카운터   |   9.4 |                                                                         | 포착되지 않은 오류를 처리하는 Rack 연결 수 |
| `redis_cache_generation_duration_seconds`                                      | 히스토그램 |  15.6 | `cache_hit`, `cache_identifier`, `feature_category`, `backing_resource` | Redis 캐시 생성 시간 |
| `redis_hit_miss_operations_total`                                              | 카운터   |  15.6 | `cache_hit`, `cache_identifier`, `feature_category`, `backing_resource` | Redis 캐시 히트 및 미스의 총 수 |
| `search_advanced_boolean_settings`                                             | 게이지     |  17.3 | `name`                                                                  | 고급 검색 부울 설정의 현재 상태 |
| `search_advanced_index_repair_total`                                           | 카운터   |  17.3 | `document_type`                                                         | 인덱스 복구 작업의 수를 계산합니다 |
| `service_desk_new_note_email`                                                  | 카운터   |  14.0 |                                                                         | 새로운 서비스 데스크 댓글에 대한 이메일 알림의 총 수 |
| `service_desk_thank_you_email`                                                 | 카운터   |  14.0 |                                                                         | 새로운 서비스 데스크 이메일에 대한 이메일 응답의 총 수 |
| `successful_login_captcha_total`                                               | 게이지     |  11.0 |                                                                         | 로그인 중 성공한 CAPTCHA 시도의 카운터 |
| `upload_file_does_not_exist`                                                   | 카운터   |  10.7 |                                                                         | 업로드 레코드가 해당 파일을 찾지 못한 횟수입니다. |
| `user_session_logins_total`                                                    | 카운터   |   9.4 |                                                                         | GitLab이 시작되거나 다시 시작된 이후 로그인한 사용자 수의 카운터 |
| `validity_check_network_errors_total`                                          | 카운터   |  18.6 | `partner`, `error_class`                                                | 파트너 토큰 확인 API 호출 중 총 네트워크 오류입니다. Ultimate 전용입니다. |
| `validity_check_partner_api_duration_seconds`                                  | 히스토그램 |  18.6 | `partner`                                                               | 토큰 확인 요청에 대한 파트너 API 응답 시간(초)입니다. Ultimate 전용입니다. |
| `validity_check_partner_api_requests_total`                                    | 카운터   |  18.6 | `partner`, `status`, `error_type`                                       | 성공/실패 상태의 총 파트너 API 확인 요청입니다. Ultimate 전용입니다. |
| `validity_check_rate_limit_hits_total`                                         | 카운터   |  18.6 | `limit_type`                                              | 파트너 토큰 확인 중 총 속도 제한 히트입니다. Ultimate 전용입니다. |

## 기능 플래그로 제어되는 지표 {#metrics-controlled-by-a-feature-flag}

다음 지표는 기능 플래그로 제어할 수 있습니다:

| 측정항목                                       | 기능 플래그 |
|:---------------------------------------------|:-------------|
| `gitlab_view_rendering_duration_seconds`     | `prometheus_metrics_view_instrumentation` |
| `gitlab_ci_queue_depth_total`                | `gitlab_ci_builds_queuing_metrics` |
| `gitlab_ci_queue_size`                       | `gitlab_ci_builds_queuing_metrics` |
| `gitlab_ci_queue_size_total`                 | `gitlab_ci_builds_queuing_metrics` |
| `gitlab_ci_queue_iteration_duration_seconds` | `gitlab_ci_builds_queuing_metrics` |
| `gitlab_ci_current_queue_size`               | `gitlab_ci_builds_queuing_metrics` |
| `gitlab_ci_queue_retrieval_duration_seconds` | `gitlab_ci_builds_queuing_metrics` |
| `gitlab_ci_queue_active_runners_total`       | `gitlab_ci_builds_queuing_metrics` |
| `gitaly_circuit_breaker_requests_total`      | `add_circuit_breaker_to_gitaly`    |
| `gitaly_circuit_breaker_transitions_total`   | `add_circuit_breaker_to_gitaly`    |

## Praefect 지표 {#praefect-metrics}

[Praefect를 구성](../../gitaly/praefect/configure.md#praefect)하여 지표를 보고할 수 있습니다. 사용 가능한 지표에 대한 자세한 내용은 [Gitaly 클러스터 모니터링(Praefect)](../../gitaly/praefect/monitoring.md)을 참조하세요.

## Sidekiq 지표 {#sidekiq-metrics}

Sidekiq 작업도 지표를 수집할 수 있으며, Sidekiq 내보내기가 활성화된 경우 이러한 지표에 액세스할 수 있습니다. 예를 들어 `monitoring.sidekiq_exporter` 구성 옵션을 `gitlab.yml`에서 사용합니다. 이 지표는 구성된 포트의 `/metrics` 경로에서 제공됩니다.

| 측정항목                                                   | 유형      | 이후 | 레이블                                                                                    | 설명 |
|:---------------------------------------------------------|:----------|:------|:------------------------------------------------------------------------------------------|:------------|
| `destroyed_job_artifacts_count_total`                    | 카운터   | 13.6  |                                                                                           | 삭제된 만료된 작업 아티팩트의 수 |
| `destroyed_pipeline_artifacts_count_total`               | 카운터   | 13.8  |                                                                                           | 삭제된 만료된 파이프라인 아티팩트의 수 |
| `geo_ci_secure_files_checksum_failed`                    | 게이지     | 15.3  | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 보안 파일의 수 |
| `geo_ci_secure_files_checksum_total`                     | 게이지     | 15.3  | `url`                                                                                     | 주 서버에서 체크섬할 보안 파일의 수 |
| `geo_ci_secure_files_checksummed`                        | 게이지     | 15.3  | `url`                                                                                     | 주 서버에서 체크섬 계산을 성공적으로 완료한 보안 파일의 수 |
| `geo_ci_secure_files_failed`                             | 게이지     | 15.3  | `url`                                                                                     | 보조 서버에서 동기화에 실패한 동기화 가능한 보안 파일의 수 |
| `geo_ci_secure_files_registry`                           | 게이지     | 15.3  | `url`                                                                                     | 레지스트리의 보안 파일 수 |
| `geo_ci_secure_files_synced`                             | 게이지     | 15.3  | `url`                                                                                     | 보조 서버에서 동기화된 동기화 가능한 보안 파일의 수 |
| `geo_ci_secure_files_verification_failed`                | 게이지     | 15.3  | `url`                                                                                     | 보조 서버에서 검증에 실패한 보안 파일의 수 |
| `geo_ci_secure_files_verification_total`                 | 게이지     | 15.3  | `url`                                                                                     | 보조 서버에서 검증을 시도할 보안 파일의 수 |
| `geo_ci_secure_files_verified`                           | 게이지     | 15.3  | `url`                                                                                     | 보조 서버에서 성공적으로 검증된 보안 파일의 수 |
| `geo_ci_secure_files`                                    | 게이지     | 15.3  | `url`                                                                                     | 주 서버의 보안 파일 수 |
| `geo_container_repositories_checksum_failed`             | 게이지     | 15.10 | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 컨테이너 리포지토리의 수 |
| `geo_container_repositories_checksum_total`              | 게이지     | 15.10 | `url`                                                                                     | 주 서버에서 성공적으로 체크섬된 컨테이너 리포지토리의 수 |
| `geo_container_repositories_checksummed`                 | 게이지     | 15.10 | `url`                                                                                     | 주 서버에서 체크섬을 시도한 컨테이너 리포지토리의 수 |
| `geo_container_repositories_failed`                      | 게이지     | 15.4  | `url`                                                                                     | 보조 서버에서 동기화에 실패한 동기화 가능한 컨테이너 리포지토리의 수 |
| `geo_container_repositories_registry`                    | 게이지     | 15.4  | `url`                                                                                     | 레지스트리의 컨테이너 리포지토리 수 |
| `geo_container_repositories_synced`                      | 게이지     | 15.4  | `url`                                                                                     | 보조 서버에서 동기화된 컨테이너 리포지토리의 수 |
| `geo_container_repositories_verification_failed`         | 게이지     | 15.10 | `url`                                                                                     | 보조 서버에서 검증 실패한 컨테이너 리포지토리의 수 |
| `geo_container_repositories_verification_total`          | 게이지     | 15.10 | `url`                                                                                     | 보조 서버에서 검증을 시도한 컨테이너 리포지토리의 수 |
| `geo_container_repositories_verified`                    | 게이지     | 15.10 | `url`                                                                                     | 보조 서버에서 검증된 컨테이너 리포지토리의 수 |
| `geo_container_repositories`                             | 게이지     | 15.4  | `url`                                                                                     | 주 서버의 컨테이너 리포지토리 수 |
| `geo_cursor_last_event_id`                               | 게이지     | 10.2  | `url`                                                                                     | 보조 서버에서 처리한 이벤트 로그의 마지막 데이터베이스 ID |
| `geo_cursor_last_event_timestamp`                        | 게이지     | 10.2  | `url`                                                                                     | 보조 서버에서 처리한 이벤트 로그의 마지막 UNIX 타임스탬프 |
| `geo_db_replication_lag_seconds`                         | 게이지     | 10.2  | `url`                                                                                     | 데이터베이스 복제 지연(초) |
| `geo_dependency_proxy_blob_checksum_failed`              | 게이지     | 15.6  |                                                                                           | 주 서버에서 체크섬 계산에 실패한 종속성 프록시 Blob의 수 |
| `geo_dependency_proxy_blob_checksum_total`               | 게이지     | 15.6  |                                                                                           | 주 서버에서 체크섬할 종속성 프록시 Blob의 수 |
| `geo_dependency_proxy_blob_checksummed`                  | 게이지     | 15.6  |                                                                                           | 주 서버에서 체크섬 계산을 성공적으로 완료한 종속성 프록시 Blob의 수 |
| `geo_dependency_proxy_blob_failed`                       | 게이지     | 15.6  |                                                                                           | 보조 서버에서 동기화에 실패한 종속성 프록시 Blob의 수 |
| `geo_dependency_proxy_blob_registry`                     | 게이지     | 15.6  |                                                                                           | 레지스트리의 종속성 프록시 Blob 수 |
| `geo_dependency_proxy_blob_synced`                       | 게이지     | 15.6  |                                                                                           | 보조 서버에서 동기화된 종속성 프록시 Blob의 수 |
| `geo_dependency_proxy_blob_verification_failed`          | 게이지     | 15.6  |                                                                                           | 보조 서버에서 검증에 실패한 종속성 프록시 Blob의 수 |
| `geo_dependency_proxy_blob_verification_total`           | 게이지     | 15.6  |                                                                                           | 보조 서버에서 검증을 시도할 종속성 프록시 Blob의 수 |
| `geo_dependency_proxy_blob_verified`                     | 게이지     | 15.6  |                                                                                           | 보조 서버에서 성공적으로 검증된 종속성 프록시 Blob의 수 |
| `geo_dependency_proxy_blob`                              | 게이지     | 15.6  |                                                                                           | 주 서버의 종속성 프록시 Blob 수 |
| `geo_dependency_proxy_manifests_checksum_failed`         | 게이지     | 15.6  | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 종속성 프록시 매니페스트의 수 |
| `geo_dependency_proxy_manifests_checksum_total`          | 게이지     | 15.6  | `url`                                                                                     | 주 서버에서 체크섬할 종속성 프록시 매니페스트의 수 |
| `geo_dependency_proxy_manifests_checksummed`             | 게이지     | 15.6  | `url`                                                                                     | 주 서버에서 체크섬 계산을 성공적으로 완료한 종속성 프록시 매니페스트의 수 |
| `geo_dependency_proxy_manifests_failed`                  | 게이지     | 15.6  | `url`                                                                                     | 보조 서버에서 동기화에 실패한 동기화 가능한 종속성 프록시 매니페스트의 수 |
| `geo_dependency_proxy_manifests_registry`                | 게이지     | 15.6  | `url`                                                                                     | 레지스트리의 종속성 프록시 매니페스트 수 |
| `geo_dependency_proxy_manifests_synced`                  | 게이지     | 15.6  | `url`                                                                                     | 보조 서버에서 동기화된 동기화 가능한 종속성 프록시 매니페스트의 수 |
| `geo_dependency_proxy_manifests_verification_failed`     | 게이지     | 15.6  | `url`                                                                                     | 보조 서버에서 검증에 실패한 종속성 프록시 매니페스트의 수 |
| `geo_dependency_proxy_manifests_verification_total`      | 게이지     | 15.6  | `url`                                                                                     | 보조 서버에서 검증을 시도할 종속성 프록시 매니페스트의 수 |
| `geo_dependency_proxy_manifests_verified`                | 게이지     | 15.6  | `url`                                                                                     | 보조 서버에서 성공적으로 검증된 종속성 프록시 매니페스트의 수 |
| `geo_dependency_proxy_manifests`                         | 게이지     | 15.6  | `url`                                                                                     | 주 서버의 종속성 프록시 매니페스트 수 |
| `geo_design_management_repositories_checksum_failed`     | 게이지     | 16.1  | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 설계 리포지토리의 수 |
| `geo_design_management_repositories_checksum_total`      | 게이지     | 16.1  | `url`                                                                                     | 주 서버에서 체크섬을 시도한 설계 리포지토리의 수 |
| `geo_design_management_repositories_checksummed`         | 게이지     | 16.1  | `url`                                                                                     | 주 서버에서 성공적으로 체크섬된 설계 리포지토리의 수 |
| `geo_design_management_repositories_failed`              | 게이지     | 16.1  | `url`                                                                                     | 보조 서버에서 동기화에 실패한 동기화 가능한 설계 리포지토리의 수 |
| `geo_design_management_repositories_registry`            | 게이지     | 16.1  | `url`                                                                                     | 레지스트리의 설계 리포지토리 수 |
| `geo_design_management_repositories_synced`              | 게이지     | 16.1  | `url`                                                                                     | 보조 서버에서 동기화된 동기화 가능한 설계 리포지토리의 수 |
| `geo_design_management_repositories_verification_failed` | 게이지     | 16.1  | `url`                                                                                     | 보조 서버에서 검증 실패한 설계 리포지토리의 수 |
| `geo_design_management_repositories_verification_total`  | 게이지     | 16.1  | `url`                                                                                     | 보조 서버에서 검증을 시도한 설계 리포지토리의 수 |
| `geo_design_management_repositories_verified`            | 게이지     | 16.1  | `url`                                                                                     | 보조 서버에서 검증된 설계 리포지토리의 수 |
| `geo_design_management_repositories`                     | 게이지     | 16.1  | `url`                                                                                     | 주 서버의 설계 리포지토리 수 |
| `geo_group_wiki_repositories_checksum_failed`            | 게이지     | 13.10 | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 그룹 위키의 수 |
| `geo_group_wiki_repositories_checksum_total`             | 게이지     | 16.3  | `url`                                                                                     | 주 서버에서 체크섬할 그룹 위키의 수 |
| `geo_group_wiki_repositories_checksummed`                | 게이지     | 13.10 | `url`                                                                                     | 주 서버에서 체크섬 계산을 성공적으로 완료한 그룹 위키의 수 |
| `geo_group_wiki_repositories_failed`                     | 게이지     | 13.10 | `url`                                                                                     | 보조 서버에서 동기화에 실패한 동기화 가능한 그룹 위키의 수 |
| `geo_group_wiki_repositories_registry`                   | 게이지     | 13.10 | `url`                                                                                     | 레지스트리의 그룹 위키 수 |
| `geo_group_wiki_repositories_synced`                     | 게이지     | 13.10 | `url`                                                                                     | 보조 서버에서 동기화된 동기화 가능한 그룹 위키의 수 |
| `geo_group_wiki_repositories_verification_failed`        | 게이지     | 16.3  | `url`                                                                                     | 보조 서버에서 검증 실패한 그룹 위키의 수 |
| `geo_group_wiki_repositories_verification_total`         | 게이지     | 16.3  | `url`                                                                                     | 보조 서버에서 검증을 시도할 그룹 위키의 수 |
| `geo_group_wiki_repositories_verified`                   | 게이지     | 16.3  | `url`                                                                                     | 보조 서버에서 성공적으로 검증된 그룹 위키의 수 |
| `geo_group_wiki_repositories`                            | 게이지     | 13.10 | `url`                                                                                     | 주 서버의 그룹 위키 수 |
| `geo_job_artifacts_checksum_failed`                      | 게이지     | 14.8  | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 작업 아티팩트의 수 |
| `geo_job_artifacts_checksum_total`                       | 게이지     | 14.8  | `url`                                                                                     | 주 서버에서 체크섬할 작업 아티팩트의 수 |
| `geo_job_artifacts_checksummed`                          | 게이지     | 14.8  | `url`                                                                                     | 주 서버에서 체크섬 계산을 성공적으로 완료한 작업 아티팩트의 수 |
| `geo_job_artifacts_failed`                               | 게이지     | 14.8  | `url`                                                                                     | 보조 서버에서 동기화에 실패한 동기화 가능한 작업 아티팩트의 수 |
| `geo_job_artifacts_registry`                             | 게이지     | 14.8  | `url`                                                                                     | 레지스트리의 작업 아티팩트 수 |
| `geo_job_artifacts_synced`                               | 게이지     | 14.8  | `url`                                                                                     | 보조 서버에서 동기화된 동기화 가능한 작업 아티팩트의 수 |
| `geo_job_artifacts_verification_failed`                  | 게이지     | 14.8  | `url`                                                                                     | 보조 서버에서 검증에 실패한 작업 아티팩트의 수 |
| `geo_job_artifacts_verification_total`                   | 게이지     | 14.8  | `url`                                                                                     | 보조 서버에서 검증을 시도할 작업 아티팩트의 수 |
| `geo_job_artifacts_verified`                             | 게이지     | 14.8  | `url`                                                                                     | 보조 서버에서 성공적으로 검증된 작업 아티팩트의 수 |
| `geo_job_artifacts`                                      | 게이지     | 14.8  | `url`                                                                                     | 주 서버의 작업 아티팩트 수 |
| `geo_last_event_id`                                      | 게이지     | 10.2  | `url`                                                                                     | 주 서버의 최신 이벤트 로그 항목의 데이터베이스 ID |
| `geo_last_event_timestamp`                               | 게이지     | 10.2  | `url`                                                                                     | 주 서버의 최신 이벤트 로그 항목의 UNIX 타임스탬프 |
| `geo_last_successful_status_check_timestamp`             | 게이지     | 10.2  | `url`                                                                                     | 상태가 성공적으로 업데이트된 마지막 타임스탬프 |
| `geo_lfs_objects_checksum_failed`                        | 게이지     | 14.6  | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 LFS 객체의 수 |
| `geo_lfs_objects_checksum_total`                         | 게이지     | 14.6  | `url`                                                                                     | 주 서버에서 체크섬해야 할 LFS 객체의 수 |
| `geo_lfs_objects_checksummed`                            | 게이지     | 14.6  | `url`                                                                                     | 주 서버에서 성공적으로 체크섬된 LFS 객체의 수 |
| `geo_lfs_objects_failed`                                 | 게이지     | 10.2  | `url`                                                                                     | 보조 서버에서 동기화에 실패한 동기화 가능한 LFS 객체의 수 |
| `geo_lfs_objects_registry`                               | 게이지     | 14.6  | `url`                                                                                     | 레지스트리의 LFS 객체 수 |
| `geo_lfs_objects_synced`                                 | 게이지     | 10.2  | `url`                                                                                     | 보조 서버에서 동기화된 동기화 가능한 LFS 객체의 수 |
| `geo_lfs_objects_verification_failed`                    | 게이지     | 14.6  | `url`                                                                                     | 보조 서버에서 검증에 실패한 LFS 객체의 수 |
| `geo_lfs_objects_verification_total`                     | 게이지     | 14.6  | `url`                                                                                     | 보조 서버에서 검증을 시도할 LFS 객체의 수 |
| `geo_lfs_objects_verified`                               | 게이지     | 14.6  | `url`                                                                                     | 보조 서버에서 성공적으로 검증된 LFS 객체의 수 |
| `geo_lfs_objects`                                        | 게이지     | 10.2  | `url`                                                                                     | 주 서버의 LFS 객체 수 |
| `geo_merge_request_diffs_checksum_failed`                | 게이지     | 13.4  | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 머지 리퀘스트 Diff의 수 |
| `geo_merge_request_diffs_checksum_total`                 | 게이지     | 13.12 | `url`                                                                                     | 주 서버에서 체크섬할 머지 리퀘스트 Diff의 수 |
| `geo_merge_request_diffs_checksummed`                    | 게이지     | 13.4  | `url`                                                                                     | 주 서버에서 체크섬 계산을 성공적으로 완료한 머지 리퀘스트 Diff의 수 |
| `geo_merge_request_diffs_failed`                         | 게이지     | 13.4  | `url`                                                                                     | 보조 서버에서 동기화에 실패한 동기화 가능한 머지 리퀘스트 Diff의 수 |
| `geo_merge_request_diffs_registry`                       | 게이지     | 13.4  | `url`                                                                                     | 레지스트리의 머지 리퀘스트 Diff 수 |
| `geo_merge_request_diffs_synced`                         | 게이지     | 13.4  | `url`                                                                                     | 보조 서버에서 동기화된 동기화 가능한 머지 리퀘스트 Diff의 수 |
| `geo_merge_request_diffs_verification_failed`            | 게이지     | 13.12 | `url`                                                                                     | 보조 서버에서 검증에 실패한 머지 리퀘스트 Diff의 수 |
| `geo_merge_request_diffs_verification_total`             | 게이지     | 13.12 | `url`                                                                                     | 보조 서버에서 검증을 시도할 머지 리퀘스트 Diff의 수 |
| `geo_merge_request_diffs_verified`                       | 게이지     | 13.12 | `url`                                                                                     | 보조 서버에서 성공적으로 검증된 머지 리퀘스트 Diff의 수 |
| `geo_merge_request_diffs`                                | 게이지     | 13.4  | `url`                                                                                     | 주 서버의 머지 리퀘스트 Diff 수 |
| `geo_package_files_checksum_failed`                      | 게이지     | 13.0  | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 패키지 파일의 수 |
| `geo_package_files_checksummed`                          | 게이지     | 13.0  | `url`                                                                                     | 주 서버에서 체크섬된 패키지 파일의 수 |
| `geo_package_files_failed`                               | 게이지     | 13.3  | `url`                                                                                     | 보조 서버에서 동기화에 실패한 동기화 가능한 패키지 파일의 수 |
| `geo_package_files_registry`                             | 게이지     | 13.3  | `url`                                                                                     | 레지스트리의 패키지 파일 수 |
| `geo_package_files_synced`                               | 게이지     | 13.3  | `url`                                                                                     | 보조 서버에서 동기화된 동기화 가능한 패키지 파일의 수 |
| `geo_package_files`                                      | 게이지     | 13.0  | `url`                                                                                     | 주 서버의 패키지 파일 수 |
| `geo_packages_nuget_symbols`                             | 게이지     | 18.6  | `url`                                                                                     | 주 서버의 NuGet 심볼 파일 수 |
| `geo_packages_nuget_symbols_checksum_total`              | 게이지     | 18.6  | `url`                                                                                     | 주 서버에서 체크섬할 NuGet 심볼 파일의 수 |
| `geo_packages_nuget_symbols_checksummed`                 | 게이지     | 18.6  | `url`                                                                                     | 주 서버에서 체크섬 계산을 성공적으로 완료한 NuGet 심볼 파일의 수 |
| `geo_packages_nuget_symbols_checksum_failed`             | 게이지     | 18.6  | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 NuGet 심볼 파일의 수 |
| `geo_packages_nuget_symbols_synced`                      | 게이지     | 18.6  | `url`                                                                                     | 보조 서버에서 동기화된 동기화 가능한 NuGet 심볼 파일의 수 |
| `geo_packages_nuget_symbols_failed`                      | 게이지     | 18.6  | `url`                                                                                     | 보조 서버에서 동기화에 실패한 동기화 가능한 NuGet 심볼 파일의 수 |
| `geo_packages_nuget_symbols_registry`                    | 게이지     | 18.6  | `url`                                                                                     | 레지스트리의 NuGet 심볼 파일 수 |
| `geo_packages_nuget_symbols_verification_total`          | 게이지     | 18.6  | `url`                                                                                     | 보조 서버에서 검증을 시도할 NuGet 심볼 파일의 수 |
| `geo_packages_nuget_symbols_verified`                    | 게이지     | 18.6  | `url`                                                                                     | 보조 서버에서 성공적으로 검증된 NuGet 심볼 파일의 수 |
| `geo_packages_nuget_symbols_verification_failed`         | 게이지     | 18.6  | `url`                                                                                     | 보조 서버에서 검증에 실패한 NuGet 심볼 파일의 수 |
| `geo_packages_helm_metadata_caches`                      | 게이지     | 18.9  | `url`                                                                                     | 주 서버의 Helm 메타데이터 캐시 수 |
| `geo_packages_helm_metadata_caches_checksum_total`       | 게이지     | 18.9  | `url`                                                                                     | 주 서버에서 체크섬할 Helm 메타데이터 캐시의 수 |
| `geo_packages_helm_metadata_caches_checksummed`          | 게이지     | 18.9  | `url`                                                                                     | 주 서버에서 체크섬 계산을 성공적으로 완료한 Helm 메타데이터 캐시의 수 |
| `geo_packages_helm_metadata_caches_checksum_failed`      | 게이지     | 18.9  | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 Helm 메타데이터 캐시의 수 |
| `geo_packages_helm_metadata_caches_synced`               | 게이지     | 18.9  | `url`                                                                                     | 보조 서버에서 동기화된 동기화 가능한 Helm 메타데이터 캐시의 수 |
| `geo_packages_helm_metadata_caches_failed`               | 게이지     | 18.9  | `url`                                                                                     | 보조 서버에서 동기화에 실패한 동기화 가능한 Helm 메타데이터 캐시의 수 |
| `geo_packages_helm_metadata_caches_registry`             | 게이지     | 18.9  | `url`                                                                                     | 레지스트리의 Helm 메타데이터 캐시 수 |
| `geo_packages_helm_metadata_caches_verification_total`   | 게이지     | 18.9  | `url`                                                                                     | 보조 서버에서 검증을 시도할 Helm 메타데이터 캐시의 수 |
| `geo_packages_helm_metadata_caches_verified`             | 게이지     | 18.9  | `url`                                                                                     | 보조 서버에서 성공적으로 검증된 Helm 메타데이터 캐시의 수 |
| `geo_packages_helm_metadata_caches_verification_failed`  | 게이지     | 18.9  | `url`                                                                                     | 보조 서버에서 검증에 실패한 Helm 메타데이터 캐시의 수 |
| `geo_pages_deployments_checksum_failed`                  | 게이지     | 14.6  | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 페이지 배포의 수 |
| `geo_pages_deployments_checksum_total`                   | 게이지     | 14.6  | `url`                                                                                     | 주 서버에서 체크섬할 페이지 배포의 수 |
| `geo_pages_deployments_checksummed`                      | 게이지     | 14.6  | `url`                                                                                     | 주 서버에서 체크섬 계산을 성공적으로 완료한 페이지 배포의 수 |
| `geo_pages_deployments_failed`                           | 게이지     | 14.3  | `url`                                                                                     | 보조 서버에서 동기화에 실패한 동기화 가능한 페이지 배포의 수 |
| `geo_pages_deployments_registry`                         | 게이지     | 14.3  | `url`                                                                                     | 레지스트리의 페이지 배포 수 |
| `geo_pages_deployments_synced`                           | 게이지     | 14.3  | `url`                                                                                     | 보조 서버에서 동기화된 동기화 가능한 페이지 배포의 수 |
| `geo_pages_deployments_verification_failed`              | 게이지     | 14.6  | `url`                                                                                     | 보조 서버에서 검증 실패한 페이지 배포의 수 |
| `geo_pages_deployments_verification_total`               | 게이지     | 14.6  | `url`                                                                                     | 보조 서버에서 검증을 시도할 페이지 배포의 수 |
| `geo_pages_deployments_verified`                         | 게이지     | 14.6  | `url`                                                                                     | 보조 서버에서 성공적으로 검증된 페이지 배포의 수 |
| `geo_pages_deployments`                                  | 게이지     | 14.3  | `url`                                                                                     | 주 서버의 페이지 배포 수 |
| `geo_project_repositories_checksum_failed`               | 게이지     | 16.2  | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 리포지토리 프로젝트의 수 |
| `geo_project_repositories_checksum_total`                | 게이지     | 16.2  | `url`                                                                                     | 주 서버에서 체크섬할 리포지토리 프로젝트의 수 |
| `geo_project_repositories_checksummed`                   | 게이지     | 16.2  | `url`                                                                                     | 프로젝트 리포지토리 중 체크섬 계산에 성공한 수 |
| `geo_project_repositories_failed`                        | 게이지     | 16.2  | `url`                                                                                     | 보조 서버에 동기화되지 않은 동기화 가능한 프로젝트 리포지토리의 수 |
| `geo_project_repositories_registry`                      | 게이지     | 16.2  | `url`                                                                                     | 레지스트리의 프로젝트 리포지토리 수 |
| `geo_project_repositories_synced`                        | 게이지     | 16.2  | `url`                                                                                     | 보조 서버에 동기화된 동기화 가능한 프로젝트 리포지토리의 수 |
| `geo_project_repositories_verification_failed`           | 게이지     | 16.2  | `url`                                                                                     | 보조 서버에서 검증에 실패한 프로젝트 리포지토리의 수 |
| `geo_project_repositories_verification_total`            | 게이지     | 16.2  | `url`                                                                                     | 보조 서버에서 검증을 시도할 프로젝트 리포지토리의 수 |
| `geo_project_repositories_verified`                      | 게이지     | 16.2  | `url`                                                                                     | 보조 서버에서 검증에 성공한 프로젝트 리포지토리의 수 |
| `geo_project_repositories`                               | 게이지     | 16.2  | `url`                                                                                     | 주 서버의 프로젝트 리포지토리 수 |
| `geo_project_wiki_repositories_checksum_failed`          | 게이지     | 15.10 | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 프로젝트 위키 리포지토리의 수 |
| `geo_project_wiki_repositories_checksum_total`           | 게이지     | 15.10 | `url`                                                                                     | 주 서버에서 체크섬을 계산할 프로젝트 위키 리포지토리의 수 |
| `geo_project_wiki_repositories_checksummed`              | 게이지     | 15.10 | `url`                                                                                     | 주 서버에서 체크섬 계산에 성공한 프로젝트 위키 리포지토리의 수 |
| `geo_project_wiki_repositories_failed`                   | 게이지     | 15.10 | `url`                                                                                     | 보조 서버에 동기화되지 않은 동기화 가능한 프로젝트 위키 리포지토리의 수 |
| `geo_project_wiki_repositories_registry`                 | 게이지     | 15.10 | `url`                                                                                     | 레지스트리의 프로젝트 위키 리포지토리 수 |
| `geo_project_wiki_repositories_synced`                   | 게이지     | 15.10 | `url`                                                                                     | 보조 서버에 동기화된 동기화 가능한 프로젝트 위키 리포지토리의 수 |
| `geo_project_wiki_repositories_verification_failed`      | 게이지     | 15.10 | `url`                                                                                     | 보조 서버에서 검증에 실패한 프로젝트 위키 리포지토리의 수 |
| `geo_project_wiki_repositories_verification_total`       | 게이지     | 15.10 | `url`                                                                                     | 보조 서버에서 검증을 시도할 프로젝트 위키 리포지토리의 수 |
| `geo_project_wiki_repositories_verified`                 | 게이지     | 15.10 | `url`                                                                                     | 보조 서버에서 검증에 성공한 프로젝트 위키 리포지토리의 수 |
| `geo_project_wiki_repositories`                          | 게이지     | 15.10 | `url`                                                                                     | 주 서버의 프로젝트 위키 리포지토리 수 |
| `geo_repositories_checksum_failed`                       | 게이지     | 10.7  | `url`                                                                                     | 17.0에서 제거 예정입니다. 16.3 및 16.4에서 누락되었습니다. `geo_project_repositories_checksum_failed`로 대체되었습니다. 주 서버에서 체크섬 계산에 실패한 리포지토리의 수 |
| `geo_repositories_checksummed`                           | 게이지     | 10.7  | `url`                                                                                     | 17.0에서 제거 예정입니다. 16.3 및 16.4에서 누락되었습니다. `geo_project_repositories_checksummed`로 대체되었습니다. 주 서버에서 체크섬을 계산한 리포지토리의 수 |
| `geo_repositories_failed`                                | 게이지     | 10.2  | `url`                                                                                     | 17.0에서 제거 예정입니다. 16.3 및 16.4에서 누락되었습니다. `geo_project_repositories_failed`로 대체되었습니다. 보조 서버에 동기화되지 않은 리포지토리의 수 |
| `geo_repositories_synced`                                | 게이지     | 10.2  | `url`                                                                                     | 17.0에서 제거 예정입니다. 16.3 및 16.4에서 누락되었습니다. `geo_project_repositories_synced`로 대체되었습니다. 보조 서버에 동기화된 리포지토리의 수 |
| `geo_repositories_verification_failed`                   | 게이지     | 10.7  | `url`                                                                                     | 17.0에서 제거 예정입니다. 16.3 및 16.4에서 누락되었습니다. `geo_project_repositories_verification_failed`로 대체되었습니다. 보조 서버에서 검증에 실패한 리포지토리의 수 |
| `geo_repositories_verified`                              | 게이지     | 10.7  | `url`                                                                                     | 17.0에서 제거 예정입니다. 16.3 및 16.4에서 누락되었습니다. `geo_project_repositories_verified`로 대체되었습니다. 보조 서버에서 검증에 성공한 리포지토리의 수 |
| `geo_repositories`                                       | 게이지     | 10.2  | `url`                                                                                     | 17.9에서 지원 중단되었습니다. 향후 GitLab 릴리스에서의 제거 일정은 아직 확정되지 않았습니다. `geo_project_repositories`을 사용하세요. 주 서버에서 사용 가능한 리포지토리의 총 수 |
| `geo_snippet_repositories_checksum_failed`               | 게이지     | 13.4  | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 스니펫의 수 |
| `geo_snippet_repositories_checksummed`                   | 게이지     | 13.4  | `url`                                                                                     | 주 서버에서 체크섬을 계산한 스니펫의 수 |
| `geo_snippet_repositories_failed`                        | 게이지     | 13.4  | `url`                                                                                     | 보조 서버에 동기화되지 않은 동기화 가능한 스니펫의 수 |
| `geo_snippet_repositories_registry`                      | 게이지     | 13.4  | `url`                                                                                     | 레지스트리의 동기화 가능한 스니펫 수 |
| `geo_snippet_repositories_synced`                        | 게이지     | 13.4  | `url`                                                                                     | 보조 서버에 동기화된 동기화 가능한 스니펫의 수 |
| `geo_snippet_repositories`                               | 게이지     | 13.4  | `url`                                                                                     | 주 서버의 스니펫 수 |
| `geo_abuse_report_uploads`                               | 게이지     | 18.10 | `url`                                                                                     | 주 서버의 악용 신고 업로드 수 |
| `geo_abuse_report_uploads_checksum_total`                | 게이지     | 18.10 | `url`                                                                                     | 주 서버에서 체크섬을 계산할 악용 신고 업로드의 수 |
| `geo_abuse_report_uploads_checksummed`                   | 게이지     | 18.10 | `url`                                                                                     | 주 서버에서 체크섬 계산에 성공한 악용 신고 업로드의 수 |
| `geo_abuse_report_uploads_checksum_failed`               | 게이지     | 18.10 | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 악용 신고 업로드의 수 |
| `geo_abuse_report_uploads_synced`                        | 게이지     | 18.10 | `url`                                                                                     | 보조 서버에 동기화된 동기화 가능한 악용 신고 업로드의 수 |
| `geo_abuse_report_uploads_failed`                        | 게이지     | 18.10 | `url`                                                                                     | 보조 서버에 동기화되지 않은 동기화 가능한 악용 신고 업로드의 수 |
| `geo_abuse_report_uploads_registry`                      | 게이지     | 18.10 | `url`                                                                                     | 레지스트리의 악용 신고 업로드 수 |
| `geo_abuse_report_uploads_verification_total`            | 게이지     | 18.10 | `url`                                                                                     | 보조 서버에서 검증을 시도할 악용 신고 업로드의 수 |
| `geo_abuse_report_uploads_verified`                      | 게이지     | 18.10 | `url`                                                                                     | 보조 서버에서 검증에 성공한 악용 신고 업로드의 수 |
| `geo_abuse_report_uploads_verification_failed`           | 게이지     | 18.10 | `url`                                                                                     | 보조 서버에서 검증에 실패한 악용 신고 업로드의 수 |
| `geo_project_uploads`                                    | 게이지     | 18.10 | `url`                                                                                     | 주 서버의 프로젝트 업로드 수 |
| `geo_project_uploads_checksum_total`                     | 게이지     | 18.10 | `url`                                                                                     | 주 서버에서 체크섬을 계산할 프로젝트 업로드의 수 |
| `geo_project_uploads_checksummed`                        | 게이지     | 18.10 | `url`                                                                                     | 주 서버에서 체크섬 계산에 성공한 프로젝트 업로드의 수 |
| `geo_project_uploads_checksum_failed`                    | 게이지     | 18.10 | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 프로젝트 업로드의 수 |
| `geo_project_uploads_synced`                             | 게이지     | 18.10 | `url`                                                                                     | 보조 서버에 동기화된 동기화 가능한 프로젝트 업로드의 수 |
| `geo_project_uploads_failed`                             | 게이지     | 18.10 | `url`                                                                                     | 보조 서버에 동기화되지 않은 동기화 가능한 프로젝트 업로드의 수 |
| `geo_project_uploads_registry`                           | 게이지     | 18.10 | `url`                                                                                     | 레지스트리의 프로젝트 업로드 수 |
| `geo_project_uploads_verification_total`                 | 게이지     | 18.10 | `url`                                                                                     | 보조 서버에서 검증을 시도할 프로젝트 업로드의 수 |
| `geo_project_uploads_verified`                           | 게이지     | 18.10 | `url`                                                                                     | 보조 서버에서 검증에 성공한 프로젝트 업로드의 수 |
| `geo_project_uploads_verification_failed`                | 게이지     | 18.10 | `url`                                                                                     | 보조 서버에서 검증에 실패한 프로젝트 업로드의 수 |
| `geo_group_uploads`                                      | 게이지     | 18.11 | `url`                                                                                     | 주 서버의 그룹 업로드 수 |
| `geo_group_uploads_checksum_total`                       | 게이지     | 18.11 | `url`                                                                                     | 주 서버에서 체크섬을 계산할 그룹 업로드의 수 |
| `geo_group_uploads_checksummed`                          | 게이지     | 18.11 | `url`                                                                                     | 주 서버에서 체크섬 계산에 성공한 그룹 업로드의 수 |
| `geo_group_uploads_checksum_failed`                      | 게이지     | 18.11 | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 그룹 업로드의 수 |
| `geo_group_uploads_synced`                               | 게이지     | 18.11 | `url`                                                                                     | 보조 서버에 동기화된 동기화 가능한 그룹 업로드의 수 |
| `geo_group_uploads_failed`                               | 게이지     | 18.11 | `url`                                                                                     | 보조 서버에 동기화되지 않은 동기화 가능한 그룹 업로드의 수 |
| `geo_group_uploads_registry`                             | 게이지     | 18.11 | `url`                                                                                     | 레지스트리의 그룹 업로드 수 |
| `geo_group_uploads_verification_total`                   | 게이지     | 18.11 | `url`                                                                                     | 보조 서버에서 검증을 시도할 그룹 업로드의 수 |
| `geo_group_uploads_verified`                             | 게이지     | 18.11 | `url`                                                                                     | 보조 서버에서 검증에 성공한 그룹 업로드의 수 |
| `geo_group_uploads_verification_failed`                  | 게이지     | 18.11 | `url`                                                                                     | 보조 서버에서 검증에 실패한 그룹 업로드의 수 |
| `geo_user_uploads`                                       | 게이지     | 18.11 | `url`                                                                                     | 주 서버의 사용자 업로드 수 |
| `geo_user_uploads_checksum_total`                        | 게이지     | 18.11 | `url`                                                                                     | 주 서버에서 체크섬을 계산할 사용자 업로드의 수 |
| `geo_user_uploads_checksummed`                           | 게이지     | 18.11 | `url`                                                                                     | 주 서버에서 체크섬 계산에 성공한 사용자 업로드의 수 |
| `geo_user_uploads_checksum_failed`                       | 게이지     | 18.11 | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 사용자 업로드의 수 |
| `geo_user_uploads_synced`                                | 게이지     | 18.11 | `url`                                                                                     | 보조 서버에 동기화된 동기화 가능한 사용자 업로드의 수 |
| `geo_user_uploads_failed`                                | 게이지     | 18.11 | `url`                                                                                     | 보조 서버에 동기화되지 않은 동기화 가능한 사용자 업로드의 수 |
| `geo_user_uploads_registry`                              | 게이지     | 18.11 | `url`                                                                                     | 레지스트리의 사용자 업로드 수 |
| `geo_user_uploads_verification_total`                    | 게이지     | 18.11 | `url`                                                                                     | 보조 서버에서 검증을 시도할 사용자 업로드의 수 |
| `geo_user_uploads_verified`                              | 게이지     | 18.11 | `url`                                                                                     | 보조 서버에서 검증에 성공한 사용자 업로드의 수 |
| `geo_user_uploads_verification_failed`                   | 게이지     | 18.11 | `url`                                                                                     | 보조 서버에서 검증에 실패한 사용자 업로드의 수 |
| `geo_design_management_action_uploads`                   | 게이지     | 18.11 | `url`                                                                                     | 주 서버의 디자인 관리 작업 업로드 수 |
| `geo_design_management_action_uploads_checksum_total`    | 게이지     | 18.11 | `url`                                                                                     | 주 서버에서 체크섬을 계산할 디자인 관리 작업 업로드의 수 |
| `geo_design_management_action_uploads_checksummed`       | 게이지     | 18.11 | `url`                                                                                     | 주 서버에서 체크섬 계산에 성공한 디자인 관리 작업 업로드의 수 |
| `geo_design_management_action_uploads_checksum_failed`   | 게이지     | 18.11 | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 디자인 관리 작업 업로드의 수 |
| `geo_design_management_action_uploads_synced`            | 게이지     | 18.11 | `url`                                                                                     | 보조 서버에 동기화된 동기화 가능한 디자인 관리 작업 업로드의 수 |
| `geo_design_management_action_uploads_failed`            | 게이지     | 18.11 | `url`                                                                                     | 보조 서버에 동기화되지 않은 동기화 가능한 디자인 관리 작업 업로드의 수 |
| `geo_design_management_action_uploads_registry`          | 게이지     | 18.11 | `url`                                                                                     | 레지스트리의 디자인 관리 작업 업로드 수 |
| `geo_design_management_action_uploads_verification_total`| 게이지     | 18.11 | `url`                                                                                     | 보조 서버에서 검증을 시도할 디자인 관리 작업 업로드의 수 |
| `geo_design_management_action_uploads_verified`          | 게이지     | 18.11 | `url`                                                                                     | 보조 서버에서 검증에 성공한 디자인 관리 작업 업로드의 수 |
| `geo_design_management_action_uploads_verification_failed`| 게이지     | 18.11 | `url`                                                                                     | 보조 서버에서 검증에 실패한 디자인 관리 작업 업로드의 수 |
| `geo_bulk_import_export_upload_uploads`                  | 게이지     | 19.0 | `url`                                                                                     | 주 서버의 대량 가져오기/내보내기 아카이브 파일 수 |
| `geo_bulk_import_export_upload_uploads_checksum_total`   | 게이지     | 19.0 | `url`                                                                                     | 주 서버에서 체크섬을 계산할 대량 가져오기/내보내기 아카이브 파일의 수 |
| `geo_bulk_import_export_upload_uploads_checksummed`      | 게이지     | 19.0 | `url`                                                                                     | 주 서버에서 체크섬 계산에 성공한 대량 가져오기/내보내기 아카이브 파일의 수 |
| `geo_bulk_import_export_upload_uploads_checksum_failed`  | 게이지     | 19.0 | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 대량 가져오기/내보내기 아카이브 파일의 수 |
| `geo_bulk_import_export_upload_uploads_synced`           | 게이지     | 19.0 | `url`                                                                                     | 보조 서버에 동기화된 동기화 가능한 대량 가져오기/내보내기 아카이브 파일의 수 |
| `geo_bulk_import_export_upload_uploads_failed`           | 게이지     | 19.0 | `url`                                                                                     | 보조 서버에 동기화되지 않은 동기화 가능한 대량 가져오기/내보내기 아카이브 파일의 수 |
| `geo_bulk_import_export_upload_uploads_registry`         | 게이지     | 19.0 | `url`                                                                                     | 레지스트리의 대량 가져오기/내보내기 아카이브 파일 수 |
| `geo_bulk_import_export_upload_uploads_verification_total`| 게이지     | 19.0 | `url`                                                                                     | 보조 서버에서 검증을 시도할 대량 가져오기/내보내기 아카이브 파일의 수 |
| `geo_bulk_import_export_upload_uploads_verified`         | 게이지     | 19.0 | `url`                                                                                     | 보조 서버에서 검증에 성공한 대량 가져오기/내보내기 아카이브 파일의 수 |
| `geo_bulk_import_export_upload_uploads_verification_failed`| 게이지     | 19.0 | `url`                                                                                     | 보조 서버에서 검증에 실패한 대량 가져오기/내보내기 아카이브 파일의 수 |
| `geo_achievement_uploads`                                | 게이지     | 18.11 | `url`                                                                                     | 주 서버의 성취도 업로드 수 |
| `geo_achievement_uploads_checksum_total`                 | 게이지     | 18.11 | `url`                                                                                     | 주 서버에서 체크섬을 계산할 성취도 업로드의 수 |
| `geo_achievement_uploads_checksummed`                    | 게이지     | 18.11 | `url`                                                                                     | 주 서버에서 체크섬 계산에 성공한 성취도 업로드의 수 |
| `geo_achievement_uploads_checksum_failed`                | 게이지     | 18.11 | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 성취도 업로드의 수 |
| `geo_achievement_uploads_synced`                         | 게이지     | 18.11 | `url`                                                                                     | 보조 서버에 동기화된 동기화 가능한 성취도 업로드의 수 |
| `geo_achievement_uploads_failed`                         | 게이지     | 18.11 | `url`                                                                                     | 보조 서버에 동기화되지 않은 동기화 가능한 성취도 업로드의 수 |
| `geo_achievement_uploads_registry`                       | 게이지     | 18.11 | `url`                                                                                     | 레지스트리의 성취도 업로드 수 |
| `geo_achievement_uploads_verification_total`             | 게이지     | 18.11 | `url`                                                                                     | 보조 서버에서 검증을 시도할 성취도 업로드의 수 |
| `geo_achievement_uploads_verified`                       | 게이지     | 18.11 | `url`                                                                                     | 보조 서버에서 검증에 성공한 성취도 업로드의 수 |
| `geo_achievement_uploads_verification_failed`            | 게이지     | 18.11 | `url`                                                                                     | 보조 서버에서 검증에 실패한 성취도 업로드의 수 |
| `geo_import_export_upload_uploads`                       | 게이지     | 19.0  | `url`                                                                                     | 주 서버의 가져오기/내보내기 아카이브 업로드 수 |
| `geo_import_export_upload_uploads_checksum_total`        | 게이지     | 19.0  | `url`                                                                                     | 주 서버에서 체크섬을 계산할 가져오기/내보내기 아카이브 업로드의 수 |
| `geo_import_export_upload_uploads_checksummed`           | 게이지     | 19.0  | `url`                                                                                     | 주 서버에서 체크섬 계산에 성공한 가져오기/내보내기 아카이브 업로드의 수 |
| `geo_import_export_upload_uploads_checksum_failed`       | 게이지     | 19.0  | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 가져오기/내보내기 아카이브 업로드의 수 |
| `geo_import_export_upload_uploads_synced`                | 게이지     | 19.0  | `url`                                                                                     | 보조 서버에 동기화된 동기화 가능한 가져오기/내보내기 아카이브 업로드의 수 |
| `geo_import_export_upload_uploads_failed`                | 게이지     | 19.0  | `url`                                                                                     | 보조 서버에 동기화되지 않은 동기화 가능한 가져오기/내보내기 아카이브 업로드의 수 |
| `geo_import_export_upload_uploads_registry`              | 게이지     | 19.0  | `url`                                                                                     | 레지스트리의 가져오기/내보내기 아카이브 업로드 수 |
| `geo_import_export_upload_uploads_verification_total`    | 게이지     | 19.0  | `url`                                                                                     | 보조 서버에서 검증을 시도할 가져오기/내보내기 아카이브 업로드의 수 |
| `geo_import_export_upload_uploads_verified`              | 게이지     | 19.0  | `url`                                                                                     | 보조 서버에서 검증에 성공한 가져오기/내보내기 아카이브 업로드의 수 |
| `geo_import_export_upload_uploads_verification_failed`   | 게이지     | 19.0  | `url`                                                                                     | 보조 서버에서 검증에 실패한 가져오기/내보내기 아카이브 업로드의 수 |
| `geo_vulnerability_archive_export_uploads`               | 게이지     | 19.0 | `url`                                                                                     | 주 서버의 취약성 아카이브 내보내기 업로드 수 |
| `geo_vulnerability_archive_export_uploads_checksum_total`| 게이지     | 19.0 | `url`                                                                                     | 주 서버에서 체크섬을 계산할 취약성 아카이브 내보내기 업로드의 수 |
| `geo_vulnerability_archive_export_uploads_checksummed`   | 게이지     | 19.0 | `url`                                                                                     | 주 서버에서 체크섬 계산에 성공한 취약성 아카이브 내보내기 업로드의 수 |
| `geo_vulnerability_archive_export_uploads_checksum_failed`| 게이지     | 19.0 | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 취약성 아카이브 내보내기 업로드의 수 |
| `geo_vulnerability_archive_export_uploads_synced`        | 게이지     | 19.0 | `url`                                                                                     | 보조 서버에 동기화된 동기화 가능한 취약성 아카이브 내보내기 업로드의 수 |
| `geo_vulnerability_archive_export_uploads_failed`        | 게이지     | 19.0 | `url`                                                                                     | 보조 서버에 동기화되지 않은 동기화 가능한 취약성 아카이브 내보내기 업로드의 수 |
| `geo_vulnerability_archive_export_uploads_registry`      | 게이지     | 19.0 | `url`                                                                                     | 레지스트리의 취약성 아카이브 내보내기 업로드 수 |
| `geo_vulnerability_archive_export_uploads_verification_total`| 게이지     | 19.0 | `url`                                                                                     | 보조 서버에서 검증을 시도할 취약성 아카이브 내보내기 업로드의 수 |
| `geo_vulnerability_archive_export_uploads_verified`      | 게이지     | 19.0 | `url`                                                                                     | 보조 서버에서 검증에 성공한 취약성 아카이브 내보내기 업로드의 수 |
| `geo_vulnerability_archive_export_uploads_verification_failed`| 게이지     | 19.0 | `url`                                                                                     | 보조 서버에서 검증에 실패한 취약성 아카이브 내보내기 업로드의 수 |
| `geo_project_import_export_relation_export_upload_uploads`| 게이지     | 19.0 | `url`                                                                                     | 주 서버의 프로젝트 가져오기 내보내기 관계 내보내기 업로드의 수 |
| `geo_project_import_export_relation_export_upload_uploads_checksum_total`| 게이지     | 19.0 | `url`                                                                                     | 주 서버에서 체크섬을 계산할 프로젝트 가져오기 내보내기 관계 내보내기 업로드의 수 |
| `geo_project_import_export_relation_export_upload_uploads_checksummed`| 게이지     | 19.0 | `url`                                                                                     | 주 서버에서 체크섬 계산에 성공한 프로젝트 가져오기 내보내기 관계 내보내기 업로드의 수 |
| `geo_project_import_export_relation_export_upload_uploads_checksum_failed`| 게이지     | 19.0 | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 프로젝트 가져오기 내보내기 관계 내보내기 업로드의 수 |
| `geo_project_import_export_relation_export_upload_uploads_synced`| 게이지     | 19.0 | `url`                                                                                     | 보조 서버에 동기화된 동기화 가능한 프로젝트 가져오기 내보내기 관계 내보내기 업로드의 수 |
| `geo_project_import_export_relation_export_upload_uploads_failed`| 게이지     | 19.0 | `url`                                                                                     | 보조 서버에 동기화되지 않은 동기화 가능한 프로젝트 가져오기 내보내기 관계 내보내기 업로드의 수 |
| `geo_project_import_export_relation_export_upload_uploads_registry`| 게이지     | 19.0 | `url`                                                                                     | 레지스트리의 프로젝트 가져오기 내보내기 관계 내보내기 업로드 수 |
| `geo_project_import_export_relation_export_upload_uploads_verification_total`| 게이지     | 19.0 | `url`                                                                                     | 보조 서버에서 검증을 시도할 프로젝트 가져오기 내보내기 관계 내보내기 업로드의 수 |
| `geo_project_import_export_relation_export_upload_uploads_verified`| 게이지     | 19.0 | `url`                                                                                     | 보조 서버에서 검증에 성공한 프로젝트 가져오기 내보내기 관계 내보내기 업로드의 수 |
| `geo_project_import_export_relation_export_upload_uploads_verification_failed`| 게이지     | 19.0 | `url`                                                                                     | 보조 서버에서 검증에 실패한 프로젝트 가져오기 내보내기 관계 내보내기 업로드의 수 |
| `geo_project_import_export_relation_export_upload_uploads_oldest_unsynced_time`| 게이지     | 19.0 | `url`                                                                                     | 보조 서버에서 동기화되지 않은 가장 오래된 프로젝트 가져오기 내보내기 관계 내보내기 업로드의 타임스탬프 |
| `geo_vulnerability_export_uploads`                       | 게이지     | 19.0 | `url`                                                                                     | 주 서버의 취약성 내보내기 업로드 수 |
| `geo_vulnerability_export_uploads_checksum_total`        | 게이지     | 19.0 | `url`                                                                                     | 주 서버에서 체크섬을 계산할 취약성 내보내기 업로드의 수 |
| `geo_vulnerability_export_uploads_checksummed`           | 게이지     | 19.0 | `url`                                                                                     | 주 서버에서 체크섬 계산에 성공한 취약성 내보내기 업로드의 수 |
| `geo_vulnerability_export_uploads_checksum_failed`       | 게이지     | 19.0 | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 취약성 내보내기 업로드의 수 |
| `geo_vulnerability_export_uploads_synced`                | 게이지     | 19.0 | `url`                                                                                     | 보조 서버에 동기화된 동기화 가능한 취약성 내보내기 업로드의 수 |
| `geo_vulnerability_export_uploads_failed`                | 게이지     | 19.0 | `url`                                                                                     | 보조 서버에 동기화되지 않은 동기화 가능한 취약성 내보내기 업로드의 수 |
| `geo_vulnerability_export_uploads_registry`              | 게이지     | 19.0 | `url`                                                                                     | 레지스트리의 취약성 내보내기 업로드 수 |
| `geo_vulnerability_export_uploads_verification_total`    | 게이지     | 19.0 | `url`                                                                                     | 보조 서버에서 검증을 시도할 취약성 내보내기 업로드의 수 |
| `geo_vulnerability_export_uploads_verified`              | 게이지     | 19.0 | `url`                                                                                     | 보조 서버에서 검증에 성공한 취약성 내보내기 업로드의 수 |
| `geo_vulnerability_export_uploads_verification_failed`   | 게이지     | 19.0 | `url`                                                                                     | 보조 서버에서 검증에 실패한 취약성 내보내기 업로드의 수 |
| `geo_user_permission_export_upload_uploads`              | 게이지     | 19.0 | `url`                                                                                     | 주 서버의 사용자 권한 내보내기 업로드 수 |
| `geo_user_permission_export_upload_uploads_checksum_total`| 게이지     | 19.0 | `url`                                                                                     | 주 서버에서 체크섬을 계산할 사용자 권한 내보내기 업로드의 수 |
| `geo_user_permission_export_upload_uploads_checksummed`  | 게이지     | 19.0 | `url`                                                                                     | 주 서버에서 체크섬 계산에 성공한 사용자 권한 내보내기 업로드의 수 |
| `geo_user_permission_export_upload_uploads_checksum_failed`| 게이지     | 19.0 | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 사용자 권한 내보내기 업로드의 수 |
| `geo_user_permission_export_upload_uploads_synced`       | 게이지     | 19.0 | `url`                                                                                     | 보조 서버에 동기화된 동기화 가능한 사용자 권한 내보내기 업로드의 수 |
| `geo_user_permission_export_upload_uploads_failed`       | 게이지     | 19.0 | `url`                                                                                     | 보조 서버에 동기화되지 않은 동기화 가능한 사용자 권한 내보내기 업로드의 수 |
| `geo_user_permission_export_upload_uploads_registry`     | 게이지     | 19.0 | `url`                                                                                     | 레지스트리의 사용자 권한 내보내기 업로드 수 |
| `geo_user_permission_export_upload_uploads_verification_total`| 게이지     | 19.0 | `url`                                                                                     | 보조 서버에서 검증을 시도할 사용자 권한 내보내기 업로드의 수 |
| `geo_user_permission_export_upload_uploads_verified`     | 게이지     | 19.0 | `url`                                                                                     | 보조 서버에서 검증에 성공한 사용자 권한 내보내기 업로드의 수 |
| `geo_user_permission_export_upload_uploads_verification_failed`| 게이지     | 19.0 | `url`                                                                                     | 보조 서버에서 검증에 실패한 사용자 권한 내보내기 업로드의 수 |
| `geo_user_permission_export_upload_uploads_oldest_unsynced_time`| 게이지     | 19.0 | `url`                                                                                     | 보조 서버에서 동기화되지 않은 가장 오래된 사용자 권한 내보내기 업로드의 타임스탬프 |
| `geo_issuable_metric_image_uploads`                      | 게이지     | 19.1 | `url`                                                                                     | 주 서버의 이슈 가능 메트릭 이미지 업로드 수 |
| `geo_issuable_metric_image_uploads_checksum_total`       | 게이지     | 19.1 | `url`                                                                                     | 주 서버에서 체크섬을 계산할 이슈 가능 메트릭 이미지 업로드의 수 |
| `geo_issuable_metric_image_uploads_checksummed`          | 게이지     | 19.1 | `url`                                                                                     | 주 서버에서 체크섬 계산에 성공한 이슈 가능 메트릭 이미지 업로드의 수 |
| `geo_issuable_metric_image_uploads_checksum_failed`      | 게이지     | 19.1 | `url`                                                                                     | 주 서버에서 체크섬 계산에 실패한 이슈 가능 메트릭 이미지 업로드의 수 |
| `geo_issuable_metric_image_uploads_synced`               | 게이지     | 19.1 | `url`                                                                                     | 보조 서버에 동기화된 동기화 가능한 이슈 가능 메트릭 이미지 업로드의 수 |
| `geo_issuable_metric_image_uploads_failed`               | 게이지     | 19.1 | `url`                                                                                     | 보조 서버에 동기화되지 않은 동기화 가능한 이슈 가능 메트릭 이미지 업로드의 수 |
| `geo_issuable_metric_image_uploads_registry`             | 게이지     | 19.1 | `url`                                                                                     | 레지스트리의 이슈 가능 메트릭 이미지 업로드 수 |
| `geo_issuable_metric_image_uploads_verification_total`   | 게이지     | 19.1 | `url`                                                                                     | 보조 서버에서 확인할 동기화 불가능한 이슈 메트릭 이미지 업로드 수 |
| `geo_issuable_metric_image_uploads_verified`             | 게이지     | 19.1 | `url`                                                                                     | 보조 서버에서 검증된 동기화 불가능한 이슈 메트릭 이미지 업로드 수 |
| `geo_issuable_metric_image_uploads_verification_failed`  | 게이지     | 19.1 | `url`                                                                                     | 보조 서버에서 검증 실패한 동기화 불가능한 이슈 메트릭 이미지 업로드 수 |
| `geo_issuable_metric_image_uploads_oldest_unsynced_time` | 게이지     | 19.1 | `url`                                                                                     | 보조 서버에서 가장 오래된 미동기화 이슈 메트릭 이미지 업로드의 타임스탬프 |
| `geo_packages_debian_project_component_files`                     | 게이지     | 19.1 | `url`                                                                                     | 기본 서버의 Debian 프로젝트 구성 요소 파일 수 |
| `geo_packages_debian_project_component_files_checksum_total`      | 게이지     | 19.1 | `url`                                                                                     | 기본 서버에서 체크섬할 Debian 프로젝트 구성 요소 파일 수 |
| `geo_packages_debian_project_component_files_checksummed`         | 게이지     | 19.1 | `url`                                                                                     | 기본 서버에서 체크섬을 성공적으로 계산한 Debian 프로젝트 구성 요소 파일 수 |
| `geo_packages_debian_project_component_files_checksum_failed`     | 게이지     | 19.1 | `url`                                                                                     | 기본 서버에서 체크섬 계산에 실패한 Debian 프로젝트 구성 요소 파일 수 |
| `geo_packages_debian_project_component_files_synced`              | 게이지     | 19.1 | `url`                                                                                     | 보조 서버에 동기화된 동기화 가능한 Debian 프로젝트 구성 요소 파일 수 |
| `geo_packages_debian_project_component_files_failed`              | 게이지     | 19.1 | `url`                                                                                     | 보조 서버에 동기화되지 않은 동기화 가능한 Debian 프로젝트 구성 요소 파일 수 |
| `geo_packages_debian_project_component_files_registry`            | 게이지     | 19.1 | `url`                                                                                     | 레지스트리의 Debian 프로젝트 구성 요소 파일 수 |
| `geo_packages_debian_project_component_files_verification_total`  | 게이지     | 19.1 | `url`                                                                                     | 보조 서버에서 검증할 Debian 프로젝트 구성 요소 파일 수 |
| `geo_packages_debian_project_component_files_verified`            | 게이지     | 19.1 | `url`                                                                                     | 보조 서버에서 검증된 Debian 프로젝트 구성 요소 파일 수 |
| `geo_packages_debian_project_component_files_verification_failed` | 게이지     | 19.1 | `url`                                                                                     | 보조 서버에서 검증 실패한 Debian 프로젝트 구성 요소 파일 수 |
| `geo_status_failed_total`                                | 카운터   | 10.2  | `url`                                                                                     | Geo 노드에서 상태를 검색하지 못한 횟수 |
| `geo_terraform_state_versions_checksum_failed`           | 게이지     | 13.5  | `url`                                                                                     | 기본 서버에서 체크섬 계산에 실패한 Terraform 상태 버전 수 |
| `geo_terraform_state_versions_checksum_total`            | 게이지     | 13.12 | `url`                                                                                     | 기본 서버에서 체크섬할 Terraform 상태 버전 수 |
| `geo_terraform_state_versions_checksummed`               | 게이지     | 13.5  | `url`                                                                                     | 기본 서버에서 성공적으로 체크섬된 Terraform 상태 버전 수 |
| `geo_terraform_state_versions_failed`                    | 게이지     | 13.5  | `url`                                                                                     | 보조 서버에 동기화되지 않은 동기화 가능한 Terraform 상태 버전 수 |
| `geo_terraform_state_versions_registry`                  | 게이지     | 13.5  | `url`                                                                                     | 레지스트리의 Terraform 상태 버전 수 |
| `geo_terraform_state_versions_synced`                    | 게이지     | 13.5  | `url`                                                                                     | 보조 서버에 동기화된 동기화 가능한 Terraform 상태 버전 수 |
| `geo_terraform_state_versions_verification_failed`       | 게이지     | 13.12 | `url`                                                                                     | 보조 서버에서 검증 실패한 Terraform 상태 버전 수 |
| `geo_terraform_state_versions_verification_total`        | 게이지     | 13.12 | `url`                                                                                     | 보조 서버에서 검증할 Terraform 상태 버전 수 |
| `geo_terraform_state_versions_verified`                  | 게이지     | 13.12 | `url`                                                                                     | 보조 서버에서 검증된 Terraform 상태 버전 수 |
| `geo_terraform_state_versions`                           | 게이지     | 13.5  | `url`                                                                                     | 기본 서버의 Terraform 상태 버전 수 |
| `geo_uploads_checksum_failed`                            | 게이지     | 14.6  | `url`                                                                                     | 기본 서버에서 체크섬 계산에 실패한 업로드 수 |
| `geo_uploads_checksum_total`                             | 게이지     | 14.6  | `url`                                                                                     | 기본 서버에서 체크섬할 업로드 수 |
| `geo_uploads_checksummed`                                | 게이지     | 14.6  | `url`                                                                                     | 기본 서버에서 체크섬을 성공적으로 계산한 업로드 수 |
| `geo_uploads_failed`                                     | 게이지     | 14.1  | `url`                                                                                     | 보조 서버에 동기화되지 않은 동기화 가능한 업로드 수 |
| `geo_uploads_registry`                                   | 게이지     | 14.1  | `url`                                                                                     | 레지스트리의 업로드 수 |
| `geo_uploads_synced`                                     | 게이지     | 14.1  | `url`                                                                                     | 보조 서버에 동기화된 업로드 수 |
| `geo_uploads_verification_failed`                        | 게이지     | 14.6  | `url`                                                                                     | 보조 서버에서 검증 실패한 업로드 수 |
| `geo_uploads_verification_total`                         | 게이지     | 14.6  | `url`                                                                                     | 보조 서버에서 검증할 업로드 수 |
| `geo_uploads_verified`                                   | 게이지     | 14.6  | `url`                                                                                     | 보조 서버에서 검증된 업로드 수 |
| `geo_uploads`                                            | 게이지     | 14.1  | `url`                                                                                     | 기본 서버의 업로드 수 |
| `gitlab_audit_event_streaming_worker_total`              | 카운터   | 18.9  | `should_stream`, `should_persist`, `streamable`                                           | 스트리밍 워커가 처리한 감사 이벤트 |
| `gitlab_ci_queue_active_runners_total`                   | 히스토그램 | 16.3  |                                                                                           | 프로젝트의 CI/CD 큐를 처리할 수 있는 활성 러너 수 |
| `gitlab_maintenance_mode`                                | 게이지     | 15.11 |                                                                                           | GitLab 유지 보수 모드가 활성화되어 있습니까? |
| `gitlab_memwd_violations_handled_total`                  | 카운터   | 15.9  |                                                                                           | Sidekiq 프로세스 메모리 위반이 처리된 총 횟수 |
| `gitlab_memwd_violations_total`                          | 카운터   | 15.9  |                                                                                           | Sidekiq 프로세스가 메모리 임계값을 위반한 총 횟수 |
| `gitlab_optimistic_locking_retries`                      | 히스토그램 | 13.10 |                                                                                           | 낙관적 재시도 잠금을 실행하기 위한 재시도 시도 수 |
| `gitlab_transaction_event_receive_email_create_issue_total`                     | 카운터   | 12.3  |                                                                                           | 이슈를 생성하는 수신된 이메일의 카운터 |
| `gitlab_transaction_event_receive_email_create_merge_request_total`             | 카운터   | 12.3  |                                                                                           | 머지 리퀘스트를 생성하는 수신된 이메일의 카운터 |
| `gitlab_transaction_event_receive_email_create_note_issuable_total`             | 카운터   | 12.3  |                                                                                           | 알림에 대한 회신이 아닐 때 이슈에 대한 댓글을 생성하는 수신된 이메일의 카운터 |
| `gitlab_transaction_event_receive_email_create_note_total`                      | 카운터   | 12.3  |                                                                                           | 알림에 대한 회신일 때 댓글을 생성하는 수신된 이메일의 카운터 |
| `gitlab_transaction_event_receive_email_service_desk_total`                     | 카운터   | 12.3  |                                                                                           | Service Desk 회신 이메일의 카운터 |
| `gitlab_transaction_event_receive_email_unsubscribe_total`                      | 카운터   | 12.3  |                                                                                           | 구독 취소 이메일의 카운터 |
| `gitlab_transaction_event_remote_mirrors_failed_total`   | 카운터   | 10.8  |                                                                                           | 실패한 원격 미러의 카운터 |
| `gitlab_transaction_event_remote_mirrors_finished_total` | 카운터   | 10.8  |                                                                                           | 완료된 원격 미러의 카운터 |
| `gitlab_transaction_event_remote_mirrors_running_total`  | 카운터   | 10.8  |                                                                                           | 실행 중인 원격 미러의 카운터 |
| `global_search_awaiting_indexing_queue_size`             | 게이지     | 13.2  |                                                                                           | 18.7에서 사용 중단 및 제거됨 `search_advanced_awaiting_indexing_queue_size`로 대체되었습니다. 색인화가 일시 중지된 동안 Elasticsearch와 동기화되기를 기다리는 데이터베이스 업데이트 수 |
| `global_search_bulk_cron_initial_queue_size`             | 게이지     | 13.1  |                                                                                           | 18.7에서 사용 중단 및 제거됨 `search_advanced_bulk_cron_initial_queue_size`로 대체되었습니다. Elasticsearch와 동기화되기를 기다리는 초기 데이터베이스 업데이트 수 |
| `global_search_bulk_cron_queue_size`                     | 게이지     | 12.10 |                                                                                           | 18.7에서 사용 중단 및 제거됨 `search_advanced_bulk_cron_queue_size`로 대체되었습니다. Elasticsearch와 동기화되기를 기다리는 증분 데이터베이스 업데이트 수 |
| `limited_capacity_worker_max_running_jobs`               | 게이지     | 13.5  | `worker`                                                                                  | 실행 중인 작업의 최대 수 |
| `limited_capacity_worker_remaining_work_count`           | 게이지     | 13.5  | `worker`                                                                                  | 대기열에 추가될 작업 수 |
| `limited_capacity_worker_running_jobs`                   | 게이지     | 13.5  | `worker`                                                                                  | 실행 중인 작업 수 |
| `search_advanced_awaiting_indexing_queue_size`           | 게이지     | 17.6  |                                                                                           | 색인화가 일시 중지된 동안 Elasticsearch와 동기화되기를 기다리는 데이터베이스 업데이트 수 |
| `search_advanced_bulk_cron_embedding_queue_size`         | 게이지     | 17.6  |                                                                                           | Elasticsearch와 동기화되기를 기다리는 임베딩 업데이트 수 |
| `search_advanced_bulk_cron_initial_queue_size`           | 게이지     | 17.6  |                                                                                           | Elasticsearch와 동기화되기를 기다리는 초기 데이터베이스 업데이트 수 |
| `search_advanced_bulk_cron_queue_size`                   | 게이지     | 17.6  |                                                                                           | Elasticsearch와 동기화되기를 기다리는 증분 데이터베이스 업데이트 수 |
| `sidekiq_concurrency_limit_current_concurrent_jobs`      | 게이지     | 17.6  | `worker`, `feature_category`                                                              | 현재 실행 중인 동시 작업 수 |
| `sidekiq_concurrency_limit_current_limit`                | 게이지     | 18.3  | `worker`, `feature_category`                                                              | 현재 스로틀 대상이 되도록 허용된 동시 작업 수 |
| `sidekiq_concurrency_limit_max_concurrent_jobs`          | 게이지     | 17.3  | `worker`, `feature_category`                                                              | 동시 실행 중인 Sidekiq 작업의 최대 수 |
| `sidekiq_concurrency_limit_queue_jobs`                   | 게이지     | 17.3  | `worker`, `feature_category`                                                              | 동시성 제한 큐에서 대기 중인 Sidekiq 작업 수 |
| `sidekiq_concurrency`                                    | 게이지     | 12.5  |                                                                                           | Sidekiq 작업의 최대 수 |
| `sidekiq_elasticsearch_requests_duration_seconds`        | 히스토그램 | 13.1  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` | Sidekiq 작업이 Elasticsearch 서버에 요청하는 데 소비한 시간(초) |
| `sidekiq_elasticsearch_requests_total`                   | 카운터   | 13.1  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` | Sidekiq 작업 실행 중 Elasticsearch 요청 수 |
| `sidekiq_jobs_completion_seconds`                        | 히스토그램 | 12.2  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` | Sidekiq 작업을 완료하기 위한 시간(초) |
| `sidekiq_jobs_cpu_seconds`                               | 히스토그램 | 12.4  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` | Sidekiq 작업을 실행하기 위한 CPU 시간(초) |
| `sidekiq_jobs_db_seconds`                                | 히스토그램 | 12.9  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` | Sidekiq 작업을 실행하기 위한 DB 시간(초) |
| `sidekiq_jobs_dead_total`                                | 카운터   | 13.7  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `urgency`               | Sidekiq 정지된 작업(재시도 시도가 소진된 작업) |
| `sidekiq_jobs_failed_total`                              | 카운터   | 12.2  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `urgency`               | 실패한 Sidekiq 작업 |
| `sidekiq_jobs_gitaly_seconds`                            | 히스토그램 | 12.9  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` | Sidekiq 작업을 실행하기 위한 Gitaly 시간(초) |
| `sidekiq_jobs_interrupted_total`                         | 카운터   | 15.2  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `urgency`               | 중단된 Sidekiq 작업 |
| `sidekiq_jobs_queue_duration_seconds`                    | 히스토그램 | 12.5  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `urgency`               | Sidekiq 작업이 실행되기 전에 대기열에 있던 시간(초) |
| `sidekiq_jobs_retried_total`                             | 카운터   | 12.2  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `urgency`               | 재시도된 Sidekiq 작업 |
| `sidekiq_jobs_skipped_total`                             | 카운터   | 16.2  | `worker`, `action`, `feature_category`, `reason`                                          | `drop_sidekiq_jobs` 기능 플래그가 활성화되었거나 `run_sidekiq_jobs` 기능 플래그가 비활성화되었을 때 건너뛴 작업 수(삭제되거나 연기됨) |
| `sidekiq_mem_total_bytes`                                | 게이지     | 15.3  |                                                                                           | 개체 슬롯을 소비하는 개체와 malloc이 필요한 개체 모두에 할당된 바이트 수 |
| `sidekiq_redis_requests_duration_seconds`                | 히스토그램 | 13.1  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` | Sidekiq 작업이 Redis 서버를 쿼리하는 데 소비한 시간(초) |
| `sidekiq_redis_requests_total`                           | 카운터   | 13.1  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` | Sidekiq 작업 실행 중 Redis 요청 수 |
| `sidekiq_running_jobs`                                   | 게이지     | 12.2  | `queue`, `boundary`, `external_dependencies`, `feature_category`, `urgency`               | 실행 중인 Sidekiq 작업 수 |
| `sidekiq_throttling_events_total`                        | 카운터   | 18.3  | `worker`, `strategy`                                                                      | Sidekiq 스로틀 이벤트의 총 수 |
| `sidekiq_watchdog_running_jobs_total`                    | 카운터   | 15.9  | `worker_class`                                                                            | RSS 제한에 도달했을 때 실행 중인 작업 |

## 데이터베이스 부하 분산 메트릭 {#database-load-balancing-metrics}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

다음 측정항목을 사용할 수 있습니다:

| 측정항목                                                  | 유형    | 이후                                                       | 레이블   | 설명 |
|:--------------------------------------------------------|:--------|:------------------------------------------------------------|:---------|:------------|
| `db_load_balancing_hosts`                               | 게이지   | [12.3](https://gitlab.com/gitlab-org/gitlab/-/issues/13630) |          | 현재 부하 분산 호스트 수 |
| `sidekiq_load_balancing_count`                          | 카운터 | 13.11                                                       | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency`, `data_consistency`, `load_balancing_strategy` | 데이터 일관성이 `:sticky` 또는 `:delayed`로 설정된 부하 분산을 사용하는 Sidekiq 작업 |
| `gitlab_transaction_caught_up_replica_pick_count_total` | 카운터 | 14.1                                                        | `result` | 따라잡은 복제본에 대한 검색 시도 수 |

## 데이터베이스 분할 메트릭 {#database-partitioning-metrics}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

다음 측정항목을 사용할 수 있습니다:

| 측정항목                  | 유형  | 이후                                                        | 설명 |
|:------------------------|:------|:-------------------------------------------------------------|:------------|
| `db_partitions_present` | 게이지 | [13.4](https://gitlab.com/gitlab-org/gitlab/-/issues/227353) | 현재 존재하는 데이터베이스 파티션 수 |
| `db_partitions_missing` | 게이지 | [13.4](https://gitlab.com/gitlab-org/gitlab/-/issues/227353) | 현재 예상되지만 존재하지 않는 데이터베이스 파티션 수 |

## 연결 풀 메트릭 {#connection-pool-metrics}

이 메트릭은 데이터베이스 [연결 풀](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/ConnectionPool.html)의 상태를 기록하며, 모든 메트릭에는 다음 레이블이 있습니다:

- `class` - 기록되는 Ruby 클래스입니다.
  - `ActiveRecord::Base`은 기본 데이터베이스 연결입니다.
  - `Geo::TrackingBase`은 Geo 추적 데이터베이스 연결입니다(활성화된 경우).
- `host` - 데이터베이스에 연결하는 데 사용되는 호스트명입니다.
- `port` - 데이터베이스에 연결하는 데 사용되는 포트입니다.

| 측정항목                                              | 유형  | 이후 | 설명 |
|:----------------------------------------------------|:------|:------|:------------|
| `gitlab_database_connection_pool_size`              | 게이지 | 13.0  | 총 연결 풀 용량 |
| `gitlab_database_connection_pool_connections`       | 게이지 | 13.0  | 풀의 현재 연결(= 유휴 + 사용 중 + 중단) |
| `gitlab_database_connection_pool_busy`              | 게이지 | 13.0  | 소유자가 여전히 활성화된 상태에서 사용 중인 연결 |
| `gitlab_database_connection_pool_dead`              | 게이지 | 13.0  | 소유자가 활성화되지 않은 상태에서 사용 중인 연결 |
| `gitlab_database_connection_pool_idle`              | 게이지 | 13.0  | 생성되었지만 현재 사용 중이 아닌 연결 |
| `gitlab_database_connection_pool_waiting`           | 게이지 | 13.0  | 이 큐에서 현재 대기 중인 스레드 |
| `gitlab_database_extended_connection_pool_busy`     | 게이지 | 17.11 | 소유자가 여전히 활성화된 상태에서 사용 중인 연결(스레드별) |
| `gitlab_database_extended_connection_pool_dead`     | 게이지 | 17.11 | 소유자가 활성화되지 않은 상태에서 사용 중인 연결(스레드별) |

`gitlab_database_extended_connection_pool_busy`과 `gitlab_database_extended_connection_pool_dead` 메트릭에는 스레드별 세분성을 위한 `thread_name` 레이블이 포함됩니다. 이 메트릭은 높은 카디널리티로 인해 기본적으로 비활성화되어 있습니다. Pod의 특정 비율에 대해 활성화하려면 `per_thread_db_connection_pool_metrics` [ops 기능 플래그](../../../development/feature_flags/_index.md)를 사용합니다.

## Ruby 메트릭 {#ruby-metrics}

사용 가능한 기본 Ruby 런타임 메트릭:

| 측정항목                                    | 유형    | 이후 | 설명 |
|:------------------------------------------|:--------|:------|:------------|
| `ruby_gc_duration_seconds`                | 카운터 | 11.1  | Ruby가 GC에 소비한 시간 |
| `ruby_gc_stat_...`                        | 게이지   | 11.1  | [GC.stat](https://ruby-doc.org/core-2.6.5/GC.html#method-c-stat)의 다양한 메트릭 |
| `ruby_gc_stat_ext_heap_fragmentation`     | 게이지   | 15.2  | 라이브 개체 대 에덴 슬롯의 Ruby 힙 단편화 정도(범위 0 ~ 1) |
| `ruby_file_descriptors`                   | 게이지   | 11.1  | 프로세스당 파일 설명자 |
| `ruby_sampler_duration_seconds`           | 카운터 | 11.1  | 통계 수집에 소비한 시간 |
| `ruby_process_cpu_seconds_total`          | 게이지   | 12.0  | 프로세스당 총 CPU 시간 |
| `ruby_process_max_fds`                    | 게이지   | 12.0  | 프로세스당 열려 있는 파일 설명자의 최대 수 |
| `ruby_process_resident_memory_bytes`      | 게이지   | 12.0  | 프로세스별 메모리 사용(RSS/상주 집합 크기) |
| `ruby_process_resident_anon_memory_bytes` | 게이지   | 15.6  | 프로세스별 익명 메모리 사용(RSS/상주 집합 크기) |
| `ruby_process_resident_file_memory_bytes` | 게이지   | 15.6  | 프로세스별 파일 기반 메모리 사용(RSS/상주 집합 크기) |
| `ruby_process_unique_memory_bytes`        | 게이지   | 13.0  | 프로세스별 메모리 사용(USS/고유 집합 크기) |
| `ruby_process_proportional_memory_bytes`  | 게이지   | 13.0  | 프로세스별 메모리 사용(PSS/비례 집합 크기) |
| `ruby_process_start_time_seconds`         | 게이지   | 12.0  | 프로세스 시작 시간의 UNIX 타임스탬프 |

## Puma 메트릭 {#puma-metrics}

| 측정항목                    | 유형  | 이후 | 설명 |
|:--------------------------|:------|:------|:------------|
| `puma_workers`            | 게이지 | 12.0  | 총 워커 수 |
| `puma_running_workers`    | 게이지 | 12.0  | 부팅된 워커 수 |
| `puma_stale_workers`      | 게이지 | 12.0  | 이전 워커의 수 |
| `puma_running`            | 게이지 | 12.0  | 실행 중인 스레드 수 |
| `puma_queued_connections` | 게이지 | 12.0  | 워커 스레드를 기다리는 해당 워커의 "할 일" 집합의 연결 수 |
| `puma_active_connections` | 게이지 | 12.0  | 요청을 처리 중인 스레드 수 |
| `puma_pool_capacity`      | 게이지 | 12.0  | 워커가 지금 바로 처리할 수 있는 요청 수 |
| `puma_max_threads`        | 게이지 | 12.0  | 워커 스레드의 최대 수 |
| `puma_idle_threads`       | 게이지 | 12.0  | 요청을 처리하지 않는 생성된 스레드의 수 |

## Redis 메트릭 {#redis-metrics}

이 클라이언트 메트릭은 Redis 서버 메트릭을 보완하기 위한 것입니다. 이 메트릭은 [Redis 인스턴스](https://docs.gitlab.com/omnibus/settings/redis/#running-with-multiple-redis-instances)별로 분류됩니다. 이 메트릭들은 Redis 인스턴스를 나타내는 `storage` 레이블을 모두 포함합니다. 예를 들어 `cache` 또는 `shared_state`입니다.

| 측정항목                                            | 유형      | 이후 | 설명 |
|:--------------------------------------------------|:----------|:------|:------------|
| `gitlab_redis_client_exceptions_total`            | 카운터   | 13.2  | Redis 클라이언트 예외 수(예외 클래스로 분류) |
| `gitlab_redis_client_requests_total`              | 카운터   | 13.2  | Redis 클라이언트 요청 수 |
| `gitlab_redis_client_requests_duration_seconds`   | 히스토그램 | 13.2  | Redis 요청 지연(차단 명령 제외) |
| `gitlab_redis_client_redirections_total`          | 카운터   | 15.10 | Redis 클러스터 MOVED/ASK 리다이렉션 수(리다이렉션 유형으로 분류) |
| `gitlab_redis_client_requests_pipelined_commands` | 히스토그램 | 16.4  | 단일 Redis 서버로 전송된 파이프라인당 명령 수 |
| `gitlab_redis_client_pipeline_redirections_count` | 히스토그램 | 17.0  | 파이프라인의 Redis 클러스터 리다이렉션 수 |

## Git LFS 메트릭 {#git-lfs-metrics}

다양한 [Git LFS](https://git-lfs.com/) 기능을 추적하기 위한 메트릭입니다.

| 측정항목                                             | 유형    | 이후 | 설명 |
|:---------------------------------------------------|:--------|:------|:------------|
| `gitlab_sli_lfs_update_objects_total`              | 카운터 | 16.10 | 업데이트된 LFS 개체의 총 수 |
| `gitlab_sli_lfs_update_objects_error_total`        | 카운터 | 16.10 | 업데이트된 LFS 개체 오류의 총 수 |
| `gitlab_sli_lfs_check_objects_total`               | 카운터 | 16.10 | 확인된 LFS 개체의 총 수 |
| `gitlab_sli_lfs_check_objects_error_total`         | 카운터 | 16.10 | 확인된 LFS 개체 오류의 총 수 |
| `gitlab_sli_lfs_validate_link_objects_total`       | 카운터 | 16.10 | 검증된 LFS 링크 개체의 총 수 |
| `gitlab_sli_lfs_validate_link_objects_error_total` | 카운터 | 16.10 | 검증된 LFS 링크 개체 오류의 총 수 |

## 시크릿 검색 파트너 토큰 검증 메트릭 {#secret-detection-partner-token-verification-metrics}

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.6에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208292)

{{< /history >}}

외부 파트너 API(AWS, GCP, Postman 등)를 사용하여 시크릿 검색 파트너 토큰 검증을 추적하는 메트릭입니다.

| 측정항목                                            | 유형      | 이후 | 레이블                                        | 설명 |
|:--------------------------------------------------|:----------|:------|:----------------------------------------------|:------------|
| `validity_check_partner_api_duration_seconds`     | 히스토그램 | 18.6  | `partner`                                     | 파트너 토큰 검증 요청의 API 응답 시간을 추적합니다. 히스토그램 버킷: [0.1, 0.25, 0.5, 1, 2, 5, 10] 초 |
| `validity_check_partner_api_requests_total`       | 카운터   | 18.6  | `partner`, `status`, `error_type`             | 파트너 API 검증 요청의 총 수입니다. `status`은 `success` 또는 `failure`일 수 있습니다. `error_type`는 실패한 경우에만 포함됩니다(예: `network_error`, `rate_limit`, `response_error`). |
| `validity_check_network_errors_total`             | 카운터   | 18.6  | `partner`, `error_class`                      | 파트너 API 호출 중 총 네트워크 오류입니다. `error_class`은 오류 유형을 나타냅니다(예: `Timeout`, `ConnectionRefused`, `HTTPError`). |
| `validity_check_rate_limit_hits_total`            | 카운터   | 18.6  | `limit_type`                    | 토큰 검증 중 총 속도 제한 히트 수입니다. `limit_type`은 파트너 속도 제한 키에 해당합니다(예: `partner_aws_api`, `partner_gcp_api`, `partner_postman_api`). |

### 파트너 레이블 {#partner-labels}

`partner` 레이블은 다음 값을 가질 수 있습니다:

- `aws` - Amazon Web Services 토큰
- `gcp` - Google Cloud Platform 토큰
- `postman` - Postman API 토큰

## 메트릭 공유 디렉터리 {#metrics-shared-directory}

GitLab Prometheus 클라이언트는 다중 프로세스 서비스 간에 공유되는 메트릭 데이터를 저장할 디렉터리가 필요합니다. 이 파일은 Puma 서버에서 실행 중인 모든 인스턴스 간에 공유됩니다. 디렉터리는 실행 중인 모든 Puma 프로세스에 액세스할 수 있어야 하거나 메트릭이 제대로 작동할 수 없습니다.

이 디렉터리의 위치는 환경 변수 `prometheus_multiproc_dir`를 사용하여 구성됩니다. 최고의 성능을 위해 `tmpfs`에서 이 디렉터리를 생성합니다.

[Linux 패키지](https://docs.gitlab.com/omnibus/)를 사용하여 GitLab을 설치했고 `tmpfs`을 사용할 수 있으면 GitLab이 메트릭 디렉터리를 구성합니다.
