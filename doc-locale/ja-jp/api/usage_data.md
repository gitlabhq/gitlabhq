---
stage: Analytics
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Service Ping API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、GitLab Service Pingプロセスとやり取りします。

## Service Pingデータをエクスポートする {#export-service-ping-data}

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141446)されました。

{{< /history >}}

`read_service_ping`スコープを持つパーソナルアクセストークンが必要です。

Service Pingで収集されたJSONペイロードを返します。アプリケーションキャッシュでペイロードデータが利用できない場合は、空のレスポンスを返します。ペイロードデータが空の場合、[Service Ping機能が有効になっている](../administration/settings/usage_statistics.md#enable-or-disable-service-ping)ことを確認し、cronジョブが実行されるのを待つか、ペイロードデータを手動で生成します。

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/usage_data/service_ping"
```

レスポンス例:

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

### `schema_inconsistencies_metric`の解釈 {#interpreting-schema_inconsistencies_metric}

Service Ping JSONペイロードには、`schema_inconsistencies_metric`が含まれています。データベーススキーマの不整合は予期されるものであり、お使いのインスタンスで問題が発生していることを示す可能性は低いです。

このメトリクスは、継続的なトラブルシューティングの問題に対してのみ設計されており、通常のヘルスチェックとして使用すべきではありません。このメトリクスは、GitLabサポートのガイダンスのみで解釈する必要があります。このメトリクスは、[データベーススキーマチェッカーRakeタスク](../administration/raketasks/maintenance.md#check-the-database-for-schema-inconsistencies)と同じデータベーススキーマの不整合をレポートします。

詳細については、[issue 467544](https://gitlab.com/gitlab-org/gitlab/-/issues/467544)を参照してください。

## 単一のYAMLファイルとしてメトリクス定義をエクスポートする {#export-metric-definitions-as-a-single-yaml-file}

インポートを容易にするために、すべてのメトリクス定義を単一のYAMLファイルとしてエクスポートします。[Metrics Dictionary](https://metrics.gitlab.com/)と同様です。

```plaintext
GET /usage_data/metric_definitions
```

リクエスト例:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/usage_data/metric_definitions"
```

レスポンス例:

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

## Service Ping SQLクエリをエクスポートする {#export-service-ping-sql-queries}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/57016) GitLab 13.11。
- [機能フラグの背後にデプロイされている](../administration/feature_flags/_index.md)、`usage_data_queries_api`という名前で、デフォルトでは無効になっています。

{{< /history >}}

Service Pingの計算に使用されるすべてのraw SQLクエリを返します。このアクションは、`usage_data_queries_api`機能フラグの背後にあり、GitLabインスタンスの[管理者](../user/permissions.md)ユーザーのみが使用できます。

```plaintext
GET /usage_data/queries
```

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/usage_data/queries"
```

レスポンス例:

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

## UsageDataNonSqlMetrics API {#usagedatanonsqlmetrics-api}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/57050) GitLab 13.11。
- [機能フラグの背後にデプロイされている](../administration/feature_flags/_index.md)、`usage_data_non_sql_metrics`という名前で、デフォルトでは無効になっています。

{{< /history >}}

Service Pingで使用されるすべての非SQLメトリクスデータを返します。このアクションは、`usage_data_non_sql_metrics`機能フラグの背後にあり、GitLabインスタンスの[管理者](../user/permissions.md)ユーザーのみが使用できます。

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/usage_data/non_sql_metrics"
```

レスポンス例:

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

## イベント追跡API {#events-tracking-api}

GitLab内の内部イベントを追跡するします。`api`または`ai_workflows`スコープを持つパーソナルアクセストークンが必要です。

イベントをSnowplowに追跡するには、`send_to_snowplow`パラメータを`true`に設定します。

リクエスト例:

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

複数のイベント追跡が必要な場合は、イベントの配列を`/track_events`エンドポイントに送信します:

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
