---
stage: Monitor
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Service Ping API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

The Service Ping API is associated with [Service Ping](../development/internal_analytics/service_ping/_index.md).

## Export Service Ping data

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141446) in GitLab 16.9.

Requires a personal access token with `read_service_ping` scope.

Returns the JSON payload collected in Service Ping. If no payload data is available in the application cache, it returns empty response.
If payload data is empty, make sure the [Service Ping feature is enabled](../administration/settings/usage_statistics.md#enable-or-disable-service-ping) and
wait for the cron job to be executed, or [generate payload data manually](../development/internal_analytics/service_ping/troubleshooting.md#generate-service-ping).

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/usage_data/service_ping"
```

Example response:

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

### Interpreting `schema_inconsistencies_metric`

The Service Ping JSON payload includes `schema_inconsistencies_metric`. Database schema inconsistencies are expected, and are unlikely to indicate a problem with your instance.

This metric is designed only for troubleshooting ongoing issues, and shouldn't be used as a regular health check. The metric should only be interpreted with
the guidance of GitLab Support. The metric reports the same database schema inconsistencies as the
[database schema checker Rake task](../administration/raketasks/maintenance.md#check-the-database-for-schema-inconsistencies).

For more information, see [issue 467544](https://gitlab.com/gitlab-org/gitlab/-/issues/467544).

## Export metric definitions as a single YAML file

Export all metric definitions as a single YAML file, similar to the [Metrics Dictionary](https://metrics.gitlab.com/), for easier importing.

```plaintext
GET /usage_data/metric_definitions
```

Example request:

```shell
curl "https://gitlab.example.com/api/v4/usage_data/metric_definitions"
```

Example response:

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

## Export Service Ping SQL queries

This action is behind the `usage_data_queries_api` feature flag and is available only for the GitLab instance [Administrator](../user/permissions.md) users.

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/57016) in GitLab 13.11.
> - [Deployed behind a feature flag](../user/feature_flags.md) named `usage_data_queries_api`, disabled by default.

Return all of the raw SQL queries used to compute Service Ping.

```plaintext
GET /usage_data/queries
```

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/usage_data/queries"
```

Example response:

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

## UsageDataNonSqlMetrics API

This action is behind the `usage_data_non_sql_metrics` feature flag and is available only for the GitLab instance [Administrator](../user/permissions.md) users.

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/57050) in GitLab 13.11.
> - [Deployed behind a feature flag](../user/feature_flags.md), named `usage_data_non_sql_metrics`, disabled by default.

Return all non-SQL metrics data used in the Service ping.

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/usage_data/non_sql_metrics"
```

Sample response:

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

## Events Tracking API

Tracks internal events in GitLab. Requires a personal access token with the `api` or `ai_workflows` scope.

To track events to Snowplow, set the `send_to_snowplow` parameter to `true`.

Example request:

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
     "https://gitlab.example.com/api/v4/usage_data/track_event"
```

If multiple events tracking is required, send an array of events to the `/track_events` endpoint:

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
     "https://gitlab.example.com/api/v4/usage_data/track_events"
```
