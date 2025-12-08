---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GeoノードAPI（非推奨）
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="warning" >}}

GeoノードAPIはGitLab 16.0で[deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/369140)になり、APIのv5で削除される予定です。代わりに[Geo Sites API](geo_sites.md)を使用してください。これは破壊的な変更です。

{{< /alert >}}

このAPIを使用して[Geoノード](../administration/geo/_index.md)を管理します。

前提要件: 

- 管理者である必要があります。

## 新しいGeoノードを作成 {#create-a-new-geo-node}

新しいGeoノードを作成します。

```plaintext
POST /geo_nodes
```

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/geo_nodes" \
  -d "name=himynameissomething" \
  -d "url=https://another-node.example.com/"
```

| 属性                   | 型    | 必須 | 説明                                                      |
| ----------------------------| ------- | -------- | -----------------------------------------------------------------|
| `primary`                   | ブール値 | いいえ       | このノードをプライマリにするかどうかを指定します。デフォルトはfalseです。 |
| `enabled`                   | ブール値 | いいえ       | Geoノードが有効になっているかどうかを示すフラグ。デフォルトはtrueです。    |
| `name`                      | 文字列  | はい      | Geoノードの固有識別子。`geo_node_name`が`gitlab.rb`で設定されている場合はそれに一致する必要があります。それ以外の場合は、`external_url`に一致する必要があります |
| `url`                       | 文字列  | はい      | Geoノードのユーザー向けURL。 |
| `internal_url`              | 文字列  | いいえ       | プライマリで定義された、セカンダリノードで接続に使用するURL。設定されていない場合は、`url`を返します。 |
| `files_max_capacity`        | 整数 | いいえ       | このセカンダリノードのLFS/添付ファイルのバックフィルの最大並行処理を制御します。デフォルトは10です。 |
| `repos_max_capacity`        | 整数 | いいえ       | このセカンダリノードのリポジトリバックフィルの最大並行処理を制御します。デフォルトは25です。 |
| `verification_max_capacity` | 整数 | いいえ       | このノードのリポジトリ検証の最大並行処理を制御します。デフォルトは100です。 |
| `container_repositories_max_capacity` | 整数  | いいえ | このノードのコンテナリポジトリの同期の最大並行処理を制御します。デフォルトは10です。 |
| `sync_object_storage`       | ブール値 | いいえ       | セカンダリGeoノードがオブジェクトストレージ内のblobをレプリケートする必要があるかどうかを示すフラグ。デフォルトはfalseです。 |
| `selective_sync_type`       | 文字列  | いいえ       | 同期を特定のグループまたはシャードのみに制限します。有効な値: `"namespaces"`、`"shards"`、または`null`。 |
| `selective_sync_shards`     | 配列   | いいえ       | `selective_sync_type` == `shards`の場合、同期されるプロジェクトのリポジトリストレージ。 |
| `selective_sync_namespace_ids` | 配列 | いいえ      | `selective_sync_type` == `namespaces`の場合、同期する必要があるグループのID。 |
| `minimum_reverification_interval` | 整数 | いいえ | リポジトリの検証が有効な間隔（日数）。期限が切れると、再検証されます。これは、セカンダリノードに設定しても効果はありません。 |

レスポンス例:

```json
{
  "id": 3,
  "name": "Test Node 1",
  "url": "https://secondary.example.com/",
  "internal_url": "https://secondary.example.com/",
  "primary": false,
  "enabled": true,
  "current": false,
  "files_max_capacity": 10,
  "repos_max_capacity": 25,
  "verification_max_capacity": 100,
  "selective_sync_type": "namespaces",
  "selective_sync_shards": [],
  "selective_sync_namespace_ids": [1, 25],
  "minimum_reverification_interval": 7,
  "container_repositories_max_capacity": 10,
  "sync_object_storage": false,
  "clone_protocol": "http",
  "web_edit_url": "https://primary.example.com/admin/geo/sites/3/edit",
  "web_geo_replication_details_url": "https://secondary.example.com/admin/geo/sites/3/replication/lfs_objects",
  "_links": {
     "self": "https://primary.example.com/api/v4/geo_nodes/3",
     "status": "https://primary.example.com/api/v4/geo_nodes/3/status",
     "repair": "https://primary.example.com/api/v4/geo_nodes/3/repair"
  }
}
```

## すべてのGeoノードに関する設定を取得 {#retrieve-configuration-about-all-geo-nodes}

```plaintext
GET /geo_nodes
```

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/geo_nodes"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "name": "us-node",
    "url": "https://primary.example.com/",
    "internal_url": "https://internal.example.com/",
    "primary": true,
    "enabled": true,
    "current": true,
    "files_max_capacity": 10,
    "repos_max_capacity": 25,
    "container_repositories_max_capacity": 10,
    "verification_max_capacity": 100,
    "selective_sync_type": "namespaces",
    "selective_sync_shards": [],
    "selective_sync_namespace_ids": [1, 25],
    "minimum_reverification_interval": 7,
    "clone_protocol": "http",
    "web_edit_url": "https://primary.example.com/admin/geo/sites/1/edit",
    "_links": {
      "self": "https://primary.example.com/api/v4/geo_nodes/1",
      "status":"https://primary.example.com/api/v4/geo_nodes/1/status",
      "repair":"https://primary.example.com/api/v4/geo_nodes/1/repair"
    }
  },
  {
    "id": 2,
    "name": "cn-node",
    "url": "https://secondary.example.com/",
    "internal_url": "https://secondary.example.com/",
    "primary": false,
    "enabled": true,
    "current": false,
    "files_max_capacity": 10,
    "repos_max_capacity": 25,
    "container_repositories_max_capacity": 10,
    "verification_max_capacity": 100,
    "selective_sync_type": "namespaces",
    "selective_sync_shards": [],
    "selective_sync_namespace_ids": [1, 25],
    "minimum_reverification_interval": 7,
    "sync_object_storage": true,
    "clone_protocol": "http",
    "web_edit_url": "https://primary.example.com/admin/geo/sites/2/edit",
    "web_geo_replication_details_url": "https://secondary.example.com/admin/geo/sites/2/replication/lfs_objects",
    "_links": {
      "self":"https://primary.example.com/api/v4/geo_nodes/2",
      "status":"https://primary.example.com/api/v4/geo_nodes/2/status",
      "repair":"https://primary.example.com/api/v4/geo_nodes/2/repair"
    }
  }
]
```

## 特定のGeoノードに関する設定を取得 {#retrieve-configuration-about-a-specific-geo-node}

```plaintext
GET /geo_nodes/:id
```

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/geo_nodes/1"
```

レスポンス例:

```json
{
  "id": 1,
  "name": "us-node",
  "url": "https://primary.example.com/",
  "internal_url": "https://primary.example.com/",
  "primary": true,
  "enabled": true,
  "current": true,
  "files_max_capacity": 10,
  "repos_max_capacity": 25,
  "container_repositories_max_capacity": 10,
  "verification_max_capacity": 100,
  "selective_sync_type": "namespaces",
  "selective_sync_shards": [],
  "selective_sync_namespace_ids": [1, 25],
  "minimum_reverification_interval": 7,
  "clone_protocol": "http",
  "web_edit_url": "https://primary.example.com/admin/geo/sites/1/edit",
  "_links": {
    "self": "https://primary.example.com/api/v4/geo_nodes/1",
    "status":"https://primary.example.com/api/v4/geo_nodes/1/status",
    "repair":"https://primary.example.com/api/v4/geo_nodes/1/repair"
  }
}
```

## Geoノードを編集 {#edit-a-geo-node}

既存のGeoノードの設定を更新します。

```plaintext
PUT /geo_nodes/:id
```

| 属性                   | 型    | 必須 | 説明                                                               |
|-----------------------------|---------|---------|---------------------------------------------------------------------------|
| `id`                        | 整数 | はい     | GeoノードのID。                                                   |
| `enabled`                   | ブール値 | いいえ      | Geoノードが有効になっているかどうかを示すフラグ。                               |
| `name`                      | 文字列  | いいえ      | Geoノードの固有識別子。`geo_node_name`が`gitlab.rb`で設定されている場合はそれに一致する必要があり、そうでない場合は`external_url`に一致する必要があります。 |
| `url`                       | 文字列  | いいえ      | Geoノードのユーザー向けURL。 |
| `internal_url`              | 文字列  | いいえ      | プライマリで定義された、セカンダリノードで接続に使用するURL。設定されていない場合は、`url`を返します。|
| `files_max_capacity`        | 整数 | いいえ      | このセカンダリノードのLFS/添付ファイルのバックフィルの最大並行処理を制御します。 |
| `repos_max_capacity`        | 整数 | いいえ      | このセカンダリノードのリポジトリバックフィルの最大並行処理を制御します。     |
| `verification_max_capacity` | 整数 | いいえ      | このノードの検証の最大並行処理を制御します。 |
| `container_repositories_max_capacity` | 整数 | いいえ      | このノードのコンテナリポジトリの同期の最大並行処理を制御します。 |
| `sync_object_storage`       | ブール値 | いいえ      | セカンダリGeoノードがオブジェクトストレージ内のblobをレプリケートする必要があるかどうかを示すフラグ。 |
| `selective_sync_type`       | 文字列  | いいえ      | 同期を特定のグループまたはシャードのみに制限します。有効な値: `"namespaces"`、`"shards"`、または`null`。 |
| `selective_sync_shards`     | 配列   | いいえ      | `selective_sync_type` == `shards`の場合、同期されるプロジェクトのリポジトリストレージ。 |
| `selective_sync_namespace_ids` | 配列 | いいえ      | `selective_sync_type` == `namespaces`の場合、同期する必要があるグループのID。 |
| `minimum_reverification_interval` | 整数 | いいえ      | リポジトリの検証が有効な間隔（日数）。期限が切れると、再検証されます。これは、セカンダリノードに設定しても効果はありません。 |

レスポンス例:

```json
{
  "id": 1,
  "name": "cn-node",
  "url": "https://secondary.example.com/",
  "internal_url": "https://secondary.example.com/",
  "primary": false,
  "enabled": true,
  "current": true,
  "files_max_capacity": 10,
  "repos_max_capacity": 25,
  "container_repositories_max_capacity": 10,
  "verification_max_capacity": 100,
  "selective_sync_type": "namespaces",
  "selective_sync_shards": [],
  "selective_sync_namespace_ids": [1, 25],
  "minimum_reverification_interval": 7,
  "sync_object_storage": true,
  "clone_protocol": "http",
  "web_edit_url": "https://primary.example.com/admin/geo/sites/2/edit",
  "web_geo_replication_details_url": "https://secondary.example.com/admin/geo/sites/2/replication/lfs_objects",
  "_links": {
    "self":"https://primary.example.com/api/v4/geo_nodes/2",
    "status":"https://primary.example.com/api/v4/geo_nodes/2/status",
    "repair":"https://primary.example.com/api/v4/geo_nodes/2/repair"
  }
}
```

## Geoノードを削除 {#delete-a-geo-node}

Geoノードを削除します。

```plaintext
DELETE /geo_nodes/:id
```

| 属性 | 型    | 必須 | 説明             |
|-----------|---------|----------|-------------------------|
| `id`      | 整数 | はい      | GeoノードのID。 |

## Geoノードを修復 {#repair-a-geo-node}

GeoノードのOAuth認証を修復するには。

_これは、プライマリGeoノードに対してのみ実行できます。_

```plaintext
POST /geo_nodes/:id/repair
```

レスポンス例:

```json
{
  "id": 1,
  "name": "us-node",
  "url": "https://primary.example.com/",
  "internal_url": "https://primary.example.com/",
  "primary": true,
  "enabled": true,
  "current": true,
  "files_max_capacity": 10,
  "repos_max_capacity": 25,
  "container_repositories_max_capacity": 10,
  "verification_max_capacity": 100,
  "clone_protocol": "http",
  "web_edit_url": "https://primary.example.com/admin/geo/sites/1/edit",
  "_links": {
    "self": "https://primary.example.com/api/v4/geo_nodes/1",
    "status":"https://primary.example.com/api/v4/geo_nodes/1/status",
    "repair":"https://primary.example.com/api/v4/geo_nodes/1/repair"
  }
}
```

## すべてのGeoノードに関するステータスを取得 {#retrieve-status-about-all-geo-nodes}

```plaintext
GET /geo_nodes/status
```

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/geo_nodes/status"
```

レスポンス例:

```json
[
  {
    "geo_node_id": 1,
    "healthy": true,
    "health": "Healthy",
    "health_status": "Healthy",
    "missing_oauth_application": false,
    "db_replication_lag_seconds": null,
    "lfs_objects_count": 5,
    "lfs_objects_checksum_total_count": 5,
    "lfs_objects_checksummed_count": 5,
    "lfs_objects_checksum_failed_count": 0,
    "lfs_objects_synced_count": null,
    "lfs_objects_failed_count": null,
    "lfs_objects_registry_count": null,
    "lfs_objects_verification_total_count": null,
    "lfs_objects_verified_count": null,
    "lfs_objects_verification_failed_count": null,
    "lfs_objects_synced_in_percentage": "0.00%",
    "lfs_objects_verified_in_percentage": "0.00%",
    "job_artifacts_count": 2,
    "job_artifacts_synced_count": null,
    "job_artifacts_failed_count": null,
    "job_artifacts_synced_in_percentage": "0.00%",
    "projects_count": 41,
    "repositories_count": 41,
    "replication_slots_count": 1,
    "replication_slots_used_count": 1,
    "replication_slots_used_in_percentage": "100.00%",
    "replication_slots_max_retained_wal_bytes": 0,
    "repositories_checked_count": 20,
    "repositories_checked_failed_count": 20,
    "repositories_checked_in_percentage": "100.00%",
    "last_event_id": 23,
    "last_event_timestamp": 1509681166,
    "cursor_last_event_id": null,
    "cursor_last_event_timestamp": 0,
    "last_successful_status_check_timestamp": 1510125024,
    "version": "10.3.0",
    "revision": "33d33a096a",
    "merge_request_diffs_count": 5,
    "merge_request_diffs_checksum_total_count": 5,
    "merge_request_diffs_checksummed_count": 5,
    "merge_request_diffs_checksum_failed_count": 0,
    "merge_request_diffs_synced_count": null,
    "merge_request_diffs_failed_count": null,
    "merge_request_diffs_registry_count": null,
    "merge_request_diffs_verification_total_count": null,
    "merge_request_diffs_verified_count": null,
    "merge_request_diffs_verification_failed_count": null,
    "merge_request_diffs_synced_in_percentage": "0.00%",
    "merge_request_diffs_verified_in_percentage": "0.00%",
    "package_files_count": 5,
    "package_files_checksum_total_count": 5,
    "package_files_checksummed_count": 5,
    "package_files_checksum_failed_count": 0,
    "package_files_synced_count": null,
    "package_files_failed_count": null,
    "package_files_registry_count": null,
    "package_files_verification_total_count": null,
    "package_files_verified_count": null,
    "package_files_verification_failed_count": null,
    "package_files_synced_in_percentage": "0.00%",
    "package_files_verified_in_percentage": "0.00%",
    "pages_deployments_count": 5,
    "pages_deployments_checksum_total_count": 5,
    "pages_deployments_checksummed_count": 5,
    "pages_deployments_checksum_failed_count": 0,
    "pages_deployments_synced_count": null,
    "pages_deployments_failed_count": null,
    "pages_deployments_registry_count": null,
    "pages_deployments_verification_total_count": null,
    "pages_deployments_verified_count": null,
    "pages_deployments_verification_failed_count": null,
    "pages_deployments_synced_in_percentage": "0.00%",
    "pages_deployments_verified_in_percentage": "0.00%",
    "terraform_state_versions_count": 5,
    "terraform_state_versions_checksum_total_count": 5,
    "terraform_state_versions_checksummed_count": 5,
    "terraform_state_versions_checksum_failed_count": 0,
    "terraform_state_versions_synced_count": null,
    "terraform_state_versions_failed_count": null,
    "terraform_state_versions_registry_count": null,
    "terraform_state_versions_verification_total_count": null,
    "terraform_state_versions_verified_count": null,
    "terraform_state_versions_verification_failed_count": null,
    "terraform_state_versions_synced_in_percentage": "0.00%",
    "terraform_state_versions_verified_in_percentage": "0.00%",
    "snippet_repositories_count": 5,
    "snippet_repositories_checksum_total_count": 5,
    "snippet_repositories_checksummed_count": 5,
    "snippet_repositories_checksum_failed_count": 0,
    "snippet_repositories_synced_count": null,
    "snippet_repositories_failed_count": null,
    "snippet_repositories_registry_count": null,
    "snippet_repositories_verification_total_count": null,
    "snippet_repositories_verified_count": null,
    "snippet_repositories_verification_failed_count": null,
    "snippet_repositories_synced_in_percentage": "0.00%",
    "snippet_repositories_verified_in_percentage": "0.00%",
    "project_wiki_repositories_count": 3,
    "project_wiki_repositories_checksum_total_count": 3,
    "project_wiki_repositories_checksummed_count": 3,
    "project_wiki_repositories_checksum_failed_count": 0,
    "project_wiki_repositories_synced_count": null,
    "project_wiki_repositories_failed_count": null,
    "project_wiki_repositories_registry_count": null,
    "project_wiki_repositories_verification_total_count":  null,
    "project_wiki_repositories_verified_count":  null,
    "project_wiki_repositories_verification_failed_count":  null,
    "project_wiki_repositories_synced_in_percentage": "0.00%",
    "project_wiki_repositories_verified_in_percentage": "0.00%",
    "group_wiki_repositories_count": 5,
    "group_wiki_repositories_checksum_total_count": 5,
    "group_wiki_repositories_checksummed_count": 5,
    "group_wiki_repositories_checksum_failed_count": 0,
    "group_wiki_repositories_synced_count": null,
    "group_wiki_repositories_failed_count": null,
    "group_wiki_repositories_registry_count": null,
    "group_wiki_repositories_verification_total_count": null,
    "group_wiki_repositories_verified_count": null,
    "group_wiki_repositories_verification_failed_count": null,
    "group_wiki_repositories_synced_in_percentage": "0.00%",
    "group_wiki_repositories_verified_in_percentage": "0.00%",
    "pipeline_artifacts_count": 5,
    "pipeline_artifacts_checksum_total_count": 5,
    "pipeline_artifacts_checksummed_count": 5,
    "pipeline_artifacts_checksum_failed_count": 0,
    "pipeline_artifacts_synced_count": null,
    "pipeline_artifacts_failed_count": null,
    "pipeline_artifacts_registry_count": null,
    "pipeline_artifacts_verification_total_count": null,
    "pipeline_artifacts_verified_count": null,
    "pipeline_artifacts_verification_failed_count": null,
    "pipeline_artifacts_synced_in_percentage": "0.00%",
    "pipeline_artifacts_verified_in_percentage": "0.00%",
    "uploads_count": 5,
    "uploads_synced_count": null,
    "uploads_failed_count": 0,
    "uploads_registry_count": null,
    "uploads_synced_in_percentage": "0.00%",
    "uploads_checksum_total_count": 5,
    "uploads_checksummed_count": 5,
    "uploads_checksum_failed_count": null,
    "uploads_verification_total_count":  null,
    "uploads_verified_count": null,
    "uploads_verification_failed_count": null,
    "uploads_verified_in_percentage": "0.00%",
    "job_artifacts_count": 5,
    "job_artifacts_checksum_total_count": 5,
    "job_artifacts_checksummed_count": 5,
    "job_artifacts_checksum_failed_count": 0,
    "job_artifacts_synced_count": 5,
    "job_artifacts_failed_count": 0,
    "job_artifacts_registry_count": 5,
    "job_artifacts_verification_total_count": 5,
    "job_artifacts_verified_count": 5,
    "job_artifacts_verification_failed_count": 0,
    "job_artifacts_synced_in_percentage": "100.00%",
    "job_artifacts_verified_in_percentage": "100.00%",
    "ci_secure_files_count": 5,
    "ci_secure_files_checksum_total_count": 5,
    "ci_secure_files_checksummed_count": 5,
    "ci_secure_files_checksum_failed_count": 0,
    "ci_secure_files_synced_count": 5,
    "ci_secure_files_failed_count": 0,
    "ci_secure_files_registry_count": 5,
    "ci_secure_files_verification_total_count": 5,
    "ci_secure_files_verified_count": 5,
    "ci_secure_files_verification_failed_count": 0,
    "ci_secure_files_synced_in_percentage": "100.00%",
    "ci_secure_files_verified_in_percentage": "100.00%",
    "dependency_proxy_blobs_count": 5,
    "dependency_proxy_blobs_checksum_total_count": 5,
    "dependency_proxy_blobs_checksummed_count": 5,
    "dependency_proxy_blobs_checksum_failed_count": 0,
    "dependency_proxy_blobs_synced_count": 5,
    "dependency_proxy_blobs_failed_count": 0,
    "dependency_proxy_blobs_registry_count": 5,
    "dependency_proxy_blobs_verification_total_count": 5,
    "dependency_proxy_blobs_verified_count": 5,
    "dependency_proxy_blobs_verification_failed_count": 0,
    "dependency_proxy_blobs_synced_in_percentage": "100.00%",
    "dependency_proxy_blobs_verified_in_percentage": "100.00%",
    "container_repositories_count": 5,
    "container_repositories_synced_count": 5,
    "container_repositories_failed_count": 0,
    "container_repositories_registry_count": 5,
    "container_repositories_synced_in_percentage": "100.00%",
    "container_repositories_checksum_total_count": 0,
    "container_repositories_checksummed_count": 0,
    "container_repositories_checksum_failed_count": 0,
    "container_repositories_verification_total_count": 0,
    "container_repositories_verified_count": 0,
    "container_repositories_verification_failed_count": 0,
    "container_repositories_verified_in_percentage": "100.00%",
    "dependency_proxy_manifests_count": 5,
    "dependency_proxy_manifests_checksum_total_count": 5,
    "dependency_proxy_manifests_checksummed_count": 5,
    "dependency_proxy_manifests_checksum_failed_count": 5,
    "dependency_proxy_manifests_synced_count": 5,
    "dependency_proxy_manifests_failed_count": 0,
    "dependency_proxy_manifests_registry_count": 5,
    "dependency_proxy_manifests_verification_total_count": 5,
    "dependency_proxy_manifests_verified_count": 5,
    "dependency_proxy_manifests_verification_failed_count": 5,
    "dependency_proxy_manifests_synced_in_percentage": "100.00%",
    "dependency_proxy_manifests_verified_in_percentage": "100.00%",
    "design_management_repositories_count": 5,
    "design_management_repositories_checksum_total_count": 5,
    "design_management_repositories_checksummed_count": 5,
    "design_management_repositories_checksum_failed_count": 5,
    "design_management_repositories_synced_count": 5,
    "design_management_repositories_failed_count": 0,
    "design_management_repositories_registry_count": 5,
    "design_management_repositories_verification_total_count": 5,
    "design_management_repositories_verified_count": 5,
    "design_management_repositories_verification_failed_count": 5,
    "design_management_repositories_synced_in_percentage": "100.00%",
    "design_management_repositories_verified_in_percentage": "100.00%",
    "project_repositories_count": 5,
    "project_repositories_checksum_total_count": 5,
    "project_repositories_checksummed_count": 5,
    "project_repositories_checksum_failed_count": 0,
    "project_repositories_synced_count": 5,
    "project_repositories_failed_count": 0,
    "project_repositories_registry_count": 5,
    "project_repositories_verification_total_count": 5,
    "project_repositories_verified_count": 5,
    "project_repositories_verification_failed_count": 0,
    "project_repositories_synced_in_percentage": "100.00%",
    "project_repositories_verified_in_percentage": "100.00%"
  },
  {
    "geo_node_id": 2,
    "healthy": true,
    "health": "Healthy",
    "health_status": "Healthy",
    "missing_oauth_application": false,
    "db_replication_lag_seconds": 0,
    "lfs_objects_count": 5,
    "lfs_objects_checksum_total_count": 5,
    "lfs_objects_checksummed_count": 5,
    "lfs_objects_checksum_failed_count": 0,
    "lfs_objects_synced_count": null,
    "lfs_objects_failed_count": null,
    "lfs_objects_registry_count": null,
    "lfs_objects_verification_total_count": null,
    "lfs_objects_verified_count": null,
    "lfs_objects_verification_failed_count": null,
    "lfs_objects_synced_in_percentage": "0.00%",
    "lfs_objects_verified_in_percentage": "0.00%",
    "job_artifacts_count": 2,
    "job_artifacts_synced_count": 1,
    "job_artifacts_failed_count": 1,
    "job_artifacts_synced_in_percentage": "50.00%",
    "design_management_repositories_count": 5,
    "design_management_repositories_synced_count": 5,
    "design_management_repositories_failed_count": 5,
    "design_management_repositories_synced_in_percentage": "100.00%",
    "design_management_repositories_checksum_total_count": 5,
    "design_management_repositories_checksummed_count": 5,
    "design_management_repositories_checksum_failed_count": 5,
    "design_management_repositories_registry_count": 5,
    "design_management_repositories_verification_total_count": 5,
    "design_management_repositories_verified_count": 5,
    "design_management_repositories_verification_failed_count": 5,
    "design_management_repositories_verified_in_percentage": "100.00%",
    "projects_count": 41,
    "repositories_count": 41,
    "replication_slots_count": null,
    "replication_slots_used_count": null,
    "replication_slots_used_in_percentage": "0.00%",
    "replication_slots_max_retained_wal_bytes": null,
    "repositories_checked_count": 5,
    "repositories_checked_failed_count": 1,
    "repositories_checked_in_percentage": "12.20%",
    "last_event_id": 23,
    "last_event_timestamp": 1509681166,
    "cursor_last_event_id": 23,
    "cursor_last_event_timestamp": 1509681166,
    "last_successful_status_check_timestamp": 1510125024,
    "version": "10.3.0",
    "revision": "33d33a096a",
    "merge_request_diffs_count": 5,
    "merge_request_diffs_checksum_total_count": 5,
    "merge_request_diffs_checksummed_count": 5,
    "merge_request_diffs_checksum_failed_count": 0,
    "merge_request_diffs_synced_count": 5,
    "merge_request_diffs_failed_count": 0,
    "merge_request_diffs_registry_count": 5,
    "merge_request_diffs_verification_total_count": 5,
    "merge_request_diffs_verified_count": 5,
    "merge_request_diffs_verification_failed_count": 0,
    "merge_request_diffs_synced_in_percentage": "100.00%",
    "merge_request_diffs_verified_in_percentage": "100.00%",
    "package_files_count": 5,
    "package_files_checksum_total_count": 5,
    "package_files_checksummed_count": 5,
    "package_files_checksum_failed_count": 0,
    "package_files_synced_count": 5,
    "package_files_failed_count": 0,
    "package_files_registry_count": 5,
    "package_files_verification_total_count": 5,
    "package_files_verified_count": 5,
    "package_files_verification_failed_count": 0,
    "package_files_synced_in_percentage": "100.00%",
    "package_files_verified_in_percentage": "100.00%",
    "packages_nuget_symbols_count": 5,
    "packages_nuget_symbols_checksum_total_count": 5,
    "packages_nuget_symbols_checksummed_count": 5,
    "packages_nuget_symbols_checksum_failed_count": 0,
    "packages_nuget_symbols_synced_count": 5,
    "packages_nuget_symbols_failed_count": 0,
    "packages_nuget_symbols_registry_count": 5,
    "packages_nuget_symbols_verification_total_count": 5,
    "packages_nuget_symbols_verified_count": 5,
    "packages_nuget_symbols_verification_failed_count": 0,
    "packages_nuget_symbols_synced_in_percentage": "100.00%",
    "packages_nuget_symbols_verified_in_percentage": "100.00%",
    "terraform_state_versions_count": 5,
    "terraform_state_versions_checksum_total_count": 5,
    "terraform_state_versions_checksummed_count": 5,
    "terraform_state_versions_checksum_failed_count": 0,
    "terraform_state_versions_synced_count": 5,
    "terraform_state_versions_failed_count": 0,
    "terraform_state_versions_registry_count": 5,
    "terraform_state_versions_verification_total_count": 5,
    "terraform_state_versions_verified_count": 5,
    "terraform_state_versions_verification_failed_count": 0,
    "terraform_state_versions_synced_in_percentage": "100.00%",
    "terraform_state_versions_verified_in_percentage": "100.00%",
    "snippet_repositories_count": 5,
    "snippet_repositories_checksum_total_count": 5,
    "snippet_repositories_checksummed_count": 5,
    "snippet_repositories_checksum_failed_count": 0,
    "snippet_repositories_synced_count": 5,
    "snippet_repositories_failed_count": 0,
    "snippet_repositories_registry_count": 5,
    "snippet_repositories_verification_total_count": 5,
    "snippet_repositories_verified_count": 5,
    "snippet_repositories_verification_failed_count": 0,
    "snippet_repositories_synced_in_percentage": "100.00%",
    "snippet_repositories_verified_in_percentage": "100.00%",
    "group_wiki_repositories_count": 5,
    "group_wiki_repositories_checksum_total_count": 5,
    "group_wiki_repositories_checksummed_count": 5,
    "group_wiki_repositories_checksum_failed_count": 0,
    "group_wiki_repositories_synced_count": 5,
    "group_wiki_repositories_failed_count": 0,
    "group_wiki_repositories_registry_count": 5,
    "group_wiki_repositories_verification_total_count": 5,
    "group_wiki_repositories_verified_count": 5,
    "group_wiki_repositories_verification_failed_count": 0,
    "group_wiki_repositories_synced_in_percentage": "100.00%",
    "group_wiki_repositories_verified_in_percentage": "100.00%",
    "pipeline_artifacts_count": 5,
    "pipeline_artifacts_checksum_total_count": 5,
    "pipeline_artifacts_checksummed_count": 5,
    "pipeline_artifacts_checksum_failed_count": 0,
    "pipeline_artifacts_synced_count": 5,
    "pipeline_artifacts_failed_count": 0,
    "pipeline_artifacts_registry_count": 5,
    "pipeline_artifacts_verification_total_count": 5,
    "pipeline_artifacts_verified_count": 5,
    "pipeline_artifacts_verification_failed_count": 0,
    "pipeline_artifacts_synced_in_percentage": "100.00%",
    "pipeline_artifacts_verified_in_percentage": "100.00%",
    "uploads_count": 5,
    "uploads_synced_count": null,
    "uploads_failed_count": 0,
    "uploads_registry_count": null,
    "uploads_synced_in_percentage": "0.00%",
    "uploads_checksum_total_count": 5,
    "uploads_checksummed_count": 5,
    "uploads_checksum_failed_count": null,
    "uploads_verification_total_count":  null,
    "uploads_verified_count": null,
    "uploads_verification_failed_count": null,
    "uploads_verified_in_percentage": "0.00%",
    "job_artifacts_count": 5,
    "job_artifacts_checksum_total_count": 5,
    "job_artifacts_checksummed_count": 5,
    "job_artifacts_checksum_failed_count": 0,
    "job_artifacts_synced_count": 5,
    "job_artifacts_failed_count": 0,
    "job_artifacts_registry_count": 5,
    "job_artifacts_verification_total_count": 5,
    "job_artifacts_verified_count": 5,
    "job_artifacts_verification_failed_count": 0,
    "job_artifacts_synced_in_percentage": "100.00%",
    "job_artifacts_verified_in_percentage": "100.00%",
    "dependency_proxy_blobs_count": 5,
    "dependency_proxy_blobs_checksum_total_count": 5,
    "dependency_proxy_blobs_checksummed_count": 5,
    "dependency_proxy_blobs_checksum_failed_count": 0,
    "dependency_proxy_blobs_synced_count": 5,
    "dependency_proxy_blobs_failed_count": 0,
    "dependency_proxy_blobs_registry_count": 5,
    "dependency_proxy_blobs_verification_total_count": 5,
    "dependency_proxy_blobs_verified_count": 5,
    "dependency_proxy_blobs_verification_failed_count": 0,
    "dependency_proxy_blobs_synced_in_percentage": "100.00%",
    "dependency_proxy_blobs_verified_in_percentage": "100.00%",
    "container_repositories_count": 5,
    "container_repositories_synced_count": 5,
    "container_repositories_failed_count": 0,
    "container_repositories_registry_count": 5,
    "container_repositories_synced_in_percentage": "100.00%",
    "container_repositories_checksum_total_count": 0,
    "container_repositories_checksummed_count": 0,
    "container_repositories_checksum_failed_count": 0,
    "container_repositories_verification_total_count": 0,
    "container_repositories_verified_count": 0,
    "container_repositories_verification_failed_count": 0,
    "container_repositories_verified_in_percentage": "100.00%",
    "dependency_proxy_manifests_count": 5,
    "dependency_proxy_manifests_checksum_total_count": 5,
    "dependency_proxy_manifests_checksummed_count": 5,
    "dependency_proxy_manifests_checksum_failed_count": 5,
    "dependency_proxy_manifests_synced_count": 5,
    "dependency_proxy_manifests_failed_count": 0,
    "dependency_proxy_manifests_registry_count": 5,
    "dependency_proxy_manifests_verification_total_count": 5,
    "dependency_proxy_manifests_verified_count": 5,
    "dependency_proxy_manifests_verification_failed_count": 5,
    "dependency_proxy_manifests_synced_in_percentage": "100.00%",
    "dependency_proxy_manifests_verified_in_percentage": "100.00%",
    "project_repositories_count": 5,
    "project_repositories_checksum_total_count": 5,
    "project_repositories_checksummed_count": 5,
    "project_repositories_checksum_failed_count": 0,
    "project_repositories_synced_count": 5,
    "project_repositories_failed_count": 0,
    "project_repositories_registry_count": 5,
    "project_repositories_verification_total_count": 5,
    "project_repositories_verified_count": 5,
    "project_repositories_verification_failed_count": 0,
    "project_repositories_synced_in_percentage": "100.00%",
    "project_repositories_verified_in_percentage": "100.00%"
  }
]
```

## 特定のGeoノードに関するステータスを取得 {#retrieve-status-about-a-specific-geo-node}

```plaintext
GET /geo_nodes/:id/status
```

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/geo_nodes/2/status"
```

レスポンス例:

```json
{
  "geo_node_id": 2,
  "healthy": true,
  "health": "Healthy",
  "health_status": "Healthy",
  "missing_oauth_application": false,
  "db_replication_lag_seconds": 0,
  "lfs_objects_count": 5,
  "lfs_objects_checksum_total_count": 5,
  "lfs_objects_checksummed_count": 5,
  "lfs_objects_checksum_failed_count": 0,
  "lfs_objects_synced_count": null,
  "lfs_objects_failed_count": null,
  "lfs_objects_registry_count": null,
  "lfs_objects_verification_total_count": null,
  "lfs_objects_verified_count": null,
  "lfs_objects_verification_failed_count": null,
  "lfs_objects_synced_in_percentage": "0.00%",
  "lfs_objects_verified_in_percentage": "0.00%",
  "job_artifacts_count": 2,
  "job_artifacts_synced_count": 1,
  "job_artifacts_failed_count": 1,
  "job_artifacts_synced_in_percentage": "50.00%",
  "projects_count": 41,
  "repositories_count": 41,
  "replication_slots_count": null,
  "replication_slots_used_count": null,
  "replication_slots_used_in_percentage": "0.00%",
  "replication_slots_max_retained_wal_bytes": null,
  "last_event_id": 23,
  "last_event_timestamp": 1509681166,
  "cursor_last_event_id": 23,
  "cursor_last_event_timestamp": 1509681166,
  "last_successful_status_check_timestamp": 1510125268,
  "version": "10.3.0",
  "revision": "33d33a096a",
  "merge_request_diffs_count": 5,
  "merge_request_diffs_checksum_total_count": 5,
  "merge_request_diffs_checksummed_count": 5,
  "merge_request_diffs_checksum_failed_count": 0,
  "merge_request_diffs_synced_count": 5,
  "merge_request_diffs_failed_count": 0,
  "merge_request_diffs_registry_count": 5,
  "merge_request_diffs_verification_total_count": 5,
  "merge_request_diffs_verified_count": 5,
  "merge_request_diffs_verification_failed_count": 0,
  "merge_request_diffs_synced_in_percentage": "100.00%",
  "merge_request_diffs_verified_in_percentage": "100.00%",
  "package_files_count": 5,
  "package_files_checksum_total_count": 5,
  "package_files_checksummed_count": 5,
  "package_files_checksum_failed_count": 0,
  "package_files_synced_count": 5,
  "package_files_failed_count": 0,
  "package_files_registry_count": 5,
  "package_files_verification_total_count": 5,
  "package_files_verified_count": 5,
  "package_files_verification_failed_count": 0,
  "package_files_synced_in_percentage": "100.00%",
  "package_files_verified_in_percentage": "100.00%",
  "terraform_state_versions_count": 5,
  "terraform_state_versions_checksum_total_count": 5,
  "terraform_state_versions_checksummed_count": 5,
  "terraform_state_versions_checksum_failed_count": 0,
  "terraform_state_versions_synced_count": 5,
  "terraform_state_versions_failed_count": 0,
  "terraform_state_versions_registry_count": 5,
  "terraform_state_versions_verification_total_count": 5,
  "terraform_state_versions_verified_count": 5,
  "terraform_state_versions_verification_failed_count": 0,
  "terraform_state_versions_synced_in_percentage": "100.00%",
  "terraform_state_versions_verified_in_percentage": "100.00%",
  "snippet_repositories_count": 5,
  "snippet_repositories_checksum_total_count": 5,
  "snippet_repositories_checksummed_count": 5,
  "snippet_repositories_checksum_failed_count": 0,
  "snippet_repositories_synced_count": 5,
  "snippet_repositories_failed_count": 0,
  "snippet_repositories_registry_count": 5,
  "snippet_repositories_verification_total_count": 5,
  "snippet_repositories_verified_count": 5,
  "snippet_repositories_verification_failed_count": 0,
  "snippet_repositories_synced_in_percentage": "100.00%",
  "snippet_repositories_verified_in_percentage": "100.00%",
  "group_wiki_repositories_count": 5,
  "group_wiki_repositories_checksum_total_count": 5,
  "group_wiki_repositories_checksummed_count": 5,
  "group_wiki_repositories_checksum_failed_count": 0,
  "group_wiki_repositories_synced_count": 5,
  "group_wiki_repositories_failed_count": 0,
  "group_wiki_repositories_registry_count": 5,
  "group_wiki_repositories_verification_total_count": 5,
  "group_wiki_repositories_verified_count": 5,
  "group_wiki_repositories_verification_failed_count": 0,
  "group_wiki_repositories_synced_in_percentage": "100.00%",
  "group_wiki_repositories_verified_in_percentage": "100.00%",
  "pipeline_artifacts_count": 5,
  "pipeline_artifacts_checksum_total_count": 5,
  "pipeline_artifacts_checksummed_count": 5,
  "pipeline_artifacts_checksum_failed_count": 0,
  "pipeline_artifacts_synced_count": 5,
  "pipeline_artifacts_failed_count": 0,
  "pipeline_artifacts_registry_count": 5,
  "pipeline_artifacts_verification_total_count": 5,
  "pipeline_artifacts_verified_count": 5,
  "pipeline_artifacts_verification_failed_count": 0,
  "pipeline_artifacts_synced_in_percentage": "100.00%",
  "pipeline_artifacts_verified_in_percentage": "100.00%",
  "uploads_count": 5,
  "uploads_synced_count": null,
  "uploads_failed_count": 0,
  "uploads_registry_count": null,
  "uploads_synced_in_percentage": "0.00%",
  "uploads_checksum_total_count": 5,
  "uploads_checksummed_count": 5,
  "uploads_checksum_failed_count": null,
  "uploads_verification_total_count":  null,
  "uploads_verified_count": null,
  "uploads_verification_failed_count": null,
  "uploads_verified_in_percentage": "0.00%",
  "job_artifacts_count": 5,
  "job_artifacts_checksum_total_count": 5,
  "job_artifacts_checksummed_count": 5,
  "job_artifacts_checksum_failed_count": 0,
  "job_artifacts_synced_count": 5,
  "job_artifacts_failed_count": 0,
  "job_artifacts_registry_count": 5,
  "job_artifacts_verification_total_count": 5,
  "job_artifacts_verified_count": 5,
  "job_artifacts_verification_failed_count": 0,
  "job_artifacts_synced_in_percentage": "100.00%",
  "job_artifacts_verified_in_percentage": "100.00%",
  "ci_secure_files_count": 5,
  "ci_secure_files_checksum_total_count": 5,
  "ci_secure_files_checksummed_count": 5,
  "ci_secure_files_checksum_failed_count": 0,
  "ci_secure_files_synced_count": 5,
  "ci_secure_files_failed_count": 0,
  "ci_secure_files_registry_count": 5,
  "ci_secure_files_verification_total_count": 5,
  "ci_secure_files_verified_count": 5,
  "ci_secure_files_verification_failed_count": 0,
  "ci_secure_files_synced_in_percentage": "100.00%",
  "ci_secure_files_verified_in_percentage": "100.00%",
  "dependency_proxy_blobs_count": 5,
  "dependency_proxy_blobs_checksum_total_count": 5,
  "dependency_proxy_blobs_checksummed_count": 5,
  "dependency_proxy_blobs_checksum_failed_count": 0,
  "dependency_proxy_blobs_synced_count": 5,
  "dependency_proxy_blobs_failed_count": 0,
  "dependency_proxy_blobs_registry_count": 5,
  "dependency_proxy_blobs_verification_total_count": 5,
  "dependency_proxy_blobs_verified_count": 5,
  "dependency_proxy_blobs_verification_failed_count": 0,
  "dependency_proxy_blobs_synced_in_percentage": "100.00%",
  "dependency_proxy_blobs_verified_in_percentage": "100.00%",
  "container_repositories_count": 5,
  "container_repositories_synced_count": 5,
  "container_repositories_failed_count": 0,
  "container_repositories_registry_count": 5,
  "container_repositories_synced_in_percentage": "100.00%",
  "container_repositories_checksum_total_count": 0,
  "container_repositories_checksummed_count": 0,
  "container_repositories_checksum_failed_count": 0,
  "container_repositories_verification_total_count": 0,
  "container_repositories_verified_count": 0,
  "container_repositories_verification_failed_count": 0,
  "container_repositories_verified_in_percentage": "100.00%",
  "dependency_proxy_manifests_count": 5,
  "dependency_proxy_manifests_checksum_total_count": 5,
  "dependency_proxy_manifests_checksummed_count": 5,
  "dependency_proxy_manifests_checksum_failed_count": 5,
  "dependency_proxy_manifests_synced_count": 5,
  "dependency_proxy_manifests_failed_count": 0,
  "dependency_proxy_manifests_registry_count": 5,
  "dependency_proxy_manifests_verification_total_count": 5,
  "dependency_proxy_manifests_verified_count": 5,
  "dependency_proxy_manifests_verification_failed_count": 5,
  "dependency_proxy_manifests_synced_in_percentage": "100.00%",
  "dependency_proxy_manifests_verified_in_percentage": "100.00%",
  "design_management_repositories_count": 5,
  "design_management_repositories_checksum_total_count": 5,
  "design_management_repositories_checksummed_count": 5,
  "design_management_repositories_checksum_failed_count": 5,
  "design_management_repositories_synced_count": 5,
  "design_management_repositories_failed_count": 0,
  "design_management_repositories_registry_count": 5,
  "design_management_repositories_verification_total_count": 5,
  "design_management_repositories_verified_count": 5,
  "design_management_repositories_verification_failed_count": 5,
  "design_management_repositories_synced_in_percentage": "100.00%",
  "design_management_repositories_verified_in_percentage": "100.00%",
  "project_repositories_count": 5,
  "project_repositories_checksum_total_count": 5,
  "project_repositories_checksummed_count": 5,
  "project_repositories_checksum_failed_count": 0,
  "project_repositories_synced_count": 5,
  "project_repositories_failed_count": 0,
  "project_repositories_registry_count": 5,
  "project_repositories_verification_total_count": 5,
  "project_repositories_verified_count": 5,
  "project_repositories_verification_failed_count": 0,
  "project_repositories_synced_in_percentage": "100.00%",
  "project_repositories_verified_in_percentage": "100.00%"
}
```

{{< alert type="note" >}}

`health_status`パラメータは「Healthy」または「Unhealthy」の状態でのみ指定できますが、`health`パラメータは空、「Healthy」、または実際のエラーメッセージを含むことができます。

{{< /alert >}}
