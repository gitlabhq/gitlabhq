---
stage: Analytics
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Service Ping API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 GitLab Service Ping 프로세스와 상호 작용합니다.

## Service Ping 데이터 내보내기 {#export-service-ping-data}

{{< history >}}

- [GitLab 16.9에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141446).

{{< /history >}}

Service Ping에서 수집한 JSON 페이로드를 내보냅니다. 애플리케이션 캐시에 페이로드 데이터가 없으면 빈 응답을 반환합니다. 페이로드 데이터가 비어 있으면 [Service Ping 기능이 활성화됨](../administration/settings/usage_statistics.md#enable-or-disable-service-ping)을 확인하고 cron 작업이 실행될 때까지 기다리거나 페이로드 데이터를 수동으로 생성하세요.

전제 조건:

- 개인 액세스 토큰이 `read_service_ping` 범위를 갖추어야 합니다.

```plaintext
GET /usage_data/service_ping
```

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/usage_data/service_ping"
```

응답 예시:

```json
  "recorded_at": "2024-01-15T23:33:50.387Z",
  "license": {},
  "counts": {
    "assignee_lists": 0,
    "ci_builds": 463,
    "ci_external_pipelines": 0,
    "ci_pipeline_config_auto_devops": 0,
    "ci_pipeline_config_repository": 0,
    "ci_triggers": 0,
    "ci_pipeline_schedules": 0
...
```

### `schema_inconsistencies_metric` 해석 {#interpreting-schema_inconsistencies_metric}

Service Ping JSON 페이로드에 `schema_inconsistencies_metric`이(가) 포함됩니다. 데이터베이스 스키마 불일치는 예상되며 인스턴스의 문제를 나타낼 가능성은 낮습니다.

이 메트릭은 진행 중인 이슈 해결용으로만 설계되었으며 정기적인 상태 확인으로 사용되지 않아야 합니다. 메트릭은 GitLab 지원팀의 지침에 따라서만 해석해야 합니다. 메트릭은 [데이터베이스 스키마 검사기 Rake 작업](../administration/raketasks/maintenance.md#check-the-database-for-schema-inconsistencies)과 동일한 데이터베이스 스키마 불일치를 보고합니다.

자세한 내용은 [이슈 467544](https://gitlab.com/gitlab-org/gitlab/-/issues/467544)를 참조하세요.

## 메트릭 정의 내보내기 {#export-metric-definitions}

모든 메트릭 정의를 단일 YAML 파일로 내보냅니다. [메트릭 사전](https://metrics.gitlab.com/)과 유사하며 더 쉬운 가져오기를 위해 설계되었습니다.

```plaintext
GET /usage_data/metric_definitions
```

요청 예시:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/usage_data/metric_definitions"
```

응답 예시:

```yaml
---
- key_path: redis_hll_counters.search.i_search_paid_monthly
  description: Calculated unique users to perform a search with a paid license enabled
    by month
  product_group: global_search
  value_type: number
  status: active
  time_frame: 28d
  data_source: redis_hll
  tier:
  - premium
  - ultimate
...
```

## 모든 Service Ping SQL 쿼리 나열 {#list-all-service-ping-sql-queries}

{{< history >}}

- [GitLab 13.11에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/57016).
- [기능 플래그 뒤에 배포됨](../administration/feature_flags/_index.md). 이름: `usage_data_queries_api`, 기본적으로 비활성화됨.

{{< /history >}}

Service Ping를 계산하는 데 사용되는 모든 원본 SQL 쿼리를 나열합니다. 이 작업은 `usage_data_queries_api` 기능 플래그 뒤에 있으며 GitLab 인스턴스 [Administrator](../user/permissions.md) 사용자만 사용할 수 있습니다.

```plaintext
GET /usage_data/queries
```

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/usage_data/queries"
```

응답 예시:

```json
{
  "recorded_at": "2021-03-23T06:31:21.267Z",
  "uuid": null,
  "hostname": "localhost",
  "version": "13.11.0-pre",
  "installation_type": "gitlab-development-kit",
  "active_user_count": "SELECT COUNT(\"users\".\"id\") FROM \"users\" WHERE (\"users\".\"state\" IN ('active')) AND (\"users\".\"user_type\" IS NULL OR \"users\".\"user_type\" IN (NULL, 6, 4))",
  "edition": "EE",
  "license_md5": "c701acc03844c45366dd175ef7a4e19c",
  "license_sha256": "366dd175ef7a4e19cc701acc03844c45366dd175ef7a4e19cc701acc03844c45",
  "license_id": null,
  "historical_max_users": 0,
  "licensee": {
    "Name": "John Doe1"
  },
  "license_user_count": null,
  "license_starts_at": "1970-01-01",
  "license_expires_at": "2022-02-23",
  "license_plan": "starter",
  "license_add_ons": {
    "GitLab_FileLocks": 1,
    "GitLab_Auditor_User": 1
  },
  "license_trial": null,
  "license_subscription_id": "0000",
  "license": {},
  "settings": {
    "ldap_encrypted_secrets_enabled": false,
    "operating_system": "mac_os_x-11.2.2"
  },
  "counts": {
    "assignee_lists": "SELECT COUNT(\"lists\".\"id\") FROM \"lists\" WHERE \"lists\".\"list_type\" = 3",
    "boards": "SELECT COUNT(\"boards\".\"id\") FROM \"boards\"",
    "ci_builds": "SELECT COUNT(\"ci_builds\".\"id\") FROM \"ci_builds\" WHERE \"ci_builds\".\"type\" = 'Ci::Build'",
    "ci_internal_pipelines": "SELECT COUNT(\"ci_pipelines\".\"id\") FROM \"ci_pipelines\" WHERE (\"ci_pipelines\".\"source\" IN (1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13) OR \"ci_pipelines\".\"source\" IS NULL)",
    "ci_external_pipelines": "SELECT COUNT(\"ci_pipelines\".\"id\") FROM \"ci_pipelines\" WHERE \"ci_pipelines\".\"source\" = 6",
    "ci_pipeline_config_auto_devops": "SELECT COUNT(\"ci_pipelines\".\"id\") FROM \"ci_pipelines\" WHERE \"ci_pipelines\".\"config_source\" = 2",
    "ci_pipeline_config_repository": "SELECT COUNT(\"ci_pipelines\".\"id\") FROM \"ci_pipelines\" WHERE \"ci_pipelines\".\"config_source\" = 1",
    "ci_runners": "SELECT COUNT(\"ci_runners\".\"id\") FROM \"ci_runners\"",
...
```

## 모든 비SQL 메트릭 나열 {#list-all-non-sql-metrics}

{{< history >}}

- [GitLab 13.11에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/57050).
- [기능 플래그 뒤에 배포됨](../administration/feature_flags/_index.md). 이름: `usage_data_non_sql_metrics`, 기본적으로 비활성화됨.

{{< /history >}}

Service Ping에서 사용되는 모든 비SQL 메트릭 데이터를 나열합니다. 이 작업은 `usage_data_non_sql_metrics` 기능 플래그 뒤에 있으며 GitLab 인스턴스 [Administrator](../user/permissions.md) 사용자만 사용할 수 있습니다.

```plaintext
GET /usage_data/non_sql_metrics
```

요청 예시:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/usage_data/non_sql_metrics"
```

응답 예시:

```json
{
  "recorded_at": "2021-03-26T07:04:03.724Z",
  "uuid": null,
  "hostname": "localhost",
  "version": "13.11.0-pre",
  "installation_type": "gitlab-development-kit",
  "active_user_count": -3,
  "edition": "EE",
  "license_md5": "bb8cd0d8a6d9569ff3f70b8927a1f949",
  "license_sha256": "366dd175ef7a4e19cc701acc03844c45366dd175ef7a4e19cc701acc03844c45",
  "license_id": null,
  "historical_max_users": 0,
  "licensee": {
    "Name": "John Doe1"
  },
  "license_user_count": null,
  "license_starts_at": "1970-01-01",
  "license_expires_at": "2022-02-26",
  "license_plan": "starter",
  "license_add_ons": {
    "GitLab_FileLocks": 1,
    "GitLab_Auditor_User": 1
  },
  "license_trial": null,
  "license_subscription_id": "0000",
  "license": {},
  "settings": {
    "ldap_encrypted_secrets_enabled": false,
    "operating_system": "mac_os_x-11.2.2"
  },
...
```

## 내부 이벤트 추적 {#track-internal-events}

GitLab 인스턴스의 내부 이벤트를 추적합니다.

전제 조건:

- 개인 액세스 토큰이 `api` 또는 `ai_workflows` 범위를 갖추어야 합니다.

```plaintext
POST /usage_data/track_event
```

Snowplow에 이벤트를 추적하려면 `send_to_snowplow` 매개변수를 `true`로 설정하세요.

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --request POST \
     --data '{
       "event": "mr_name_changed",
       "send_to_snowplow": true,
       "namespace_id": 1,
       "project_id": 1,
       "additional_properties": {
         "lang": "eng"
       }
     }' \
     --url "https://gitlab.example.com/api/v4/usage_data/track_event"
```

여러 이벤트 추적이 필요한 경우 이벤트 배열을 `/track_events` 엔드포인트로 보내세요:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --request POST \
     --data '{
       "events": [
         {
           "event": "mr_name_changed",
           "namespace_id": 1,
           "project_id": 1,
           "additional_properties": {
             "lang": "eng"
           }
         },
         {
           "event": "mr_name_changed",
           "namespace_id": 2,
           "project_id": 2,
           "additional_properties": {
             "lang": "eng"
           }
         }
       ]
     }' \
     --url "https://gitlab.example.com/api/v4/usage_data/track_events"
```
