---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GeoサイトAPI
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/369140)されました。

{{< /history >}}

GeoサイトAPIを使用して、Geoサイトのエンドポイントを管理します。

前提要件: 

- 管理者である必要があります。

## 新しいGeoサイトの作成 {#create-a-new-geo-site}

新しいGeoサイトを作成します。

```plaintext
POST /geo_sites
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/geo_sites" \
     --request POST \
     -d "name=himynameissomething" \
     -d "url=https://another-node.example.com/"
```

| 属性                             | 型    | 必須 | 説明                                                                                                                                            |
|---------------------------------------|---------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| `primary`                             | ブール値 | いいえ       | このサイトをプライマリにするかどうかを指定します。デフォルトはfalseです。                                                                                     |
| `enabled`                             | ブール値 | いいえ       | Geoサイトが有効になっているかどうかを示すフラグ。デフォルトはtrueです。                                                                                          |
| `name`                                | 文字列  | はい      | Geoサイトの固有識別子。`gitlab.rb`で設定されている場合は、`geo_node_name`と一致する必要があります。それ以外の場合は、`external_url`と一致する必要があります。                 |
| `url`                                 | 文字列  | はい      | Geoサイトのユーザー向けURL。                                                                                                                  |
| `internal_url`                        | 文字列  | いいえ       | セカンダリサイトがプライマリサイトに接続するために使用する必要がある、プライマリサイトで定義されたURL。設定されていない場合は、`url`が返されます。                                           |
| `files_max_capacity`                  | 整数 | いいえ       | このセカンダリサイトのLFS/添付ファイルのバックフィルの最大並行処理を制御します。デフォルトは10です。                                                    |
| `repos_max_capacity`                  | 整数 | いいえ       | このセカンダリサイトのリポジトリのバックフィルの最大並行処理を制御します。デフォルトは25です。                                                        |
| `verification_max_capacity`           | 整数 | いいえ       | このサイトのリポジトリの検証の最大並行処理を制御します。デフォルトは100です。                                                             |
| `container_repositories_max_capacity` | 整数 | いいえ       | このサイトのコンテナリポジトリの同期の最大並行処理を制御します。デフォルトは10です。                                                            |
| `sync_object_storage`                 | ブール値 | いいえ       | セカンダリGeoサイトがオブジェクトストレージ内のblobをレプリケートするかどうかを示すフラグ。デフォルトはfalseです。                                                 |
| `selective_sync_type`                 | 文字列  | いいえ       | 同期を特定のグループまたはシャードのみに制限します。有効な値は、`"namespaces"`、`"shards"`、または`null`です。                                                  |
| `selective_sync_shards`               | 配列   | いいえ       | `selective_sync_type` == `shards`の場合に同期されるプロジェクトのリポジトリストレージ。                                                                   |
| `selective_sync_namespace_ids`        | 配列   | いいえ       | `selective_sync_type` == `namespaces`の場合に同期されるグループのID。                                                                     |
| `minimum_reverification_interval`     | 整数 | いいえ       | リポジトリの検証が有効な間隔（日数）。期限が切れると、再検証されます。これはセカンダリサイトで設定しても効果はありません。 |

レスポンス例:

```json
{
  "id": 3,
  "name": "Test Site 1",
  "url": "https://secondary.example.com/",
  "internal_url": "https://secondary.example.com/",
  "primary": false,
  "enabled": true,
  "current": false,
  "files_max_capacity": 10,
  "repos_max_capacity": 25,
  "verification_max_capacity": 100,
  "container_repositories_max_capacity": 10,
  "selective_sync_type": "namespaces",
  "selective_sync_shards": [],
  "selective_sync_namespace_ids": [1, 25],
  "minimum_reverification_interval": 7,
  "sync_object_storage": false,
  "web_edit_url": "https://primary.example.com/admin/geo/sites/3/edit",
  "web_geo_replication_details_url": "https://secondary.example.com/admin/geo/sites/3/replication/lfs_objects",
  "_links": {
     "self": "https://primary.example.com/api/v4/geo_sites/3",
     "status": "https://primary.example.com/api/v4/geo_sites/3/status",
     "repair": "https://primary.example.com/api/v4/geo_sites/3/repair"
  }
}
```

## すべてのGeoサイトに関する設定を取得する {#retrieve-configuration-about-all-geo-sites}

```plaintext
GET /geo_sites
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/geo_sites"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "name": "us-site",
    "url": "https://primary.example.com/",
    "internal_url": "https://internal.example.com/",
    "primary": true,
    "enabled": true,
    "current": true,
    "files_max_capacity": 10,
    "repos_max_capacity": 25,
    "verification_max_capacity": 100,
    "container_repositories_max_capacity": 10,
    "selective_sync_type": "namespaces",
    "selective_sync_shards": [],
    "selective_sync_namespace_ids": [1, 25],
    "minimum_reverification_interval": 7,
    "web_edit_url": "https://primary.example.com/admin/geo/sites/1/edit",
    "_links": {
      "self": "https://primary.example.com/api/v4/geo_sites/1",
      "status":"https://primary.example.com/api/v4/geo_sites/1/status",
      "repair":"https://primary.example.com/api/v4/geo_sites/1/repair"
    }
  },
  {
    "id": 2,
    "name": "cn-site",
    "url": "https://secondary.example.com/",
    "internal_url": "https://secondary.example.com/",
    "primary": false,
    "enabled": true,
    "current": false,
    "files_max_capacity": 10,
    "repos_max_capacity": 25,
    "verification_max_capacity": 100,
    "container_repositories_max_capacity": 10,
    "selective_sync_type": "namespaces",
    "selective_sync_shards": [],
    "selective_sync_namespace_ids": [1, 25],
    "minimum_reverification_interval": 7,
    "sync_object_storage": true,
    "web_edit_url": "https://primary.example.com/admin/geo/sites/2/edit",
    "web_geo_replication_details_url": "https://secondary.example.com/admin/geo/sites/2/replication/lfs_objects",
    "_links": {
      "self":"https://primary.example.com/api/v4/geo_sites/2",
      "status":"https://primary.example.com/api/v4/geo_sites/2/status",
      "repair":"https://primary.example.com/api/v4/geo_sites/2/repair"
    }
  }
]
```

## 特定のGeoサイトに関する設定を取得する {#retrieve-configuration-about-a-specific-geo-site}

```plaintext
GET /geo_sites/:id
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/geo_sites/1"
```

レスポンス例:

```json
{
  "id": 1,
  "name": "us-site",
  "url": "https://primary.example.com/",
  "internal_url": "https://primary.example.com/",
  "primary": true,
  "enabled": true,
  "current": true,
  "files_max_capacity": 10,
  "repos_max_capacity": 25,
  "verification_max_capacity": 100,
  "container_repositories_max_capacity": 10,
  "selective_sync_type": "namespaces",
  "selective_sync_shards": [],
  "selective_sync_namespace_ids": [1, 25],
  "minimum_reverification_interval": 7,
  "web_edit_url": "https://primary.example.com/admin/geo/sites/1/edit",
  "_links": {
    "self": "https://primary.example.com/api/v4/geo_sites/1",
    "status":"https://primary.example.com/api/v4/geo_sites/1/status",
    "repair":"https://primary.example.com/api/v4/geo_sites/1/repair"
  }
}
```

## Geoサイトの編集 {#edit-a-geo-site}

既存のGeoサイトの設定を更新します。

```plaintext
PUT /geo_sites/:id
```

| 属性                             | 型    | 必須 | 説明                                                                                                                                            |
|---------------------------------------|---------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`                                  | 整数 | はい      | GeoサイトのID。                                                                                                                                |
| `enabled`                             | ブール値 | いいえ       | Geoサイトが有効になっているかどうかを示すフラグ。                                                                                                            |
| `name`                                | 文字列  | いいえ       | Geoサイトの固有識別子。`gitlab.rb`で設定されている場合は、`geo_node_name`と一致する必要があります。それ以外の場合は、`external_url`と一致する必要があります。                |
| `url`                                 | 文字列  | いいえ       | Geoサイトのユーザー向けURL。                                                                                                                   |
| `internal_url`                        | 文字列  | いいえ       | セカンダリサイトがプライマリサイトに接続するために使用する必要がある、プライマリサイトで定義されたURL。設定されていない場合は、`url`が返されます。                                           |
| `files_max_capacity`                  | 整数 | いいえ       | このセカンダリサイトのLFS/添付ファイルのバックフィルの最大並行処理を制御します。                                                                    |
| `repos_max_capacity`                  | 整数 | いいえ       | このセカンダリサイトのリポジトリのバックフィルの最大並行処理を制御します。                                                                        |
| `verification_max_capacity`           | 整数 | いいえ       | このサイトの検証の最大並行処理を制御します。                                                                                         |
| `container_repositories_max_capacity` | 整数 | いいえ       | このサイトのコンテナリポジトリの同期の最大並行処理を制御します。                                                                            |
| `selective_sync_type`                 | 文字列  | いいえ       | 同期を特定のグループまたはシャードのみに制限します。有効な値は、`"namespaces"`、`"shards"`、または`null`です。                                                  |
| `selective_sync_shards`               | 配列   | いいえ       | `selective_sync_type` == `shards`の場合に同期されるプロジェクトのリポジトリストレージ。                                                                   |
| `selective_sync_namespace_ids`        | 配列   | いいえ       | `selective_sync_type` == `namespaces`の場合に同期されるグループのID。                                                                     |
| `minimum_reverification_interval`     | 整数 | いいえ       | リポジトリの検証が有効な間隔（日数）。期限が切れると、再検証されます。これはセカンダリサイトで設定しても効果はありません。 |

レスポンス例:

```json
{
  "id": 1,
  "name": "us-site",
  "url": "https://primary.example.com/",
  "internal_url": "https://internal.example.com/",
  "primary": true,
  "enabled": true,
  "current": true,
  "files_max_capacity": 10,
  "repos_max_capacity": 25,
  "verification_max_capacity": 100,
  "container_repositories_max_capacity": 10,
  "selective_sync_type": "namespaces",
  "selective_sync_shards": [],
  "selective_sync_namespace_ids": [1, 25],
  "minimum_reverification_interval": 7,
  "web_edit_url": "https://primary.example.com/admin/geo/sites/1/edit",
  "_links": {
    "self": "https://primary.example.com/api/v4/geo_sites/1",
    "status": "https://primary.example.com/api/v4/geo_sites/1/status",
    "repair": "https://primary.example.com/api/v4/geo_sites/1/repair"
  }
}

```

## Geoサイトの削除 {#delete-a-geo-site}

Geoサイトを削除します。

```plaintext
DELETE /geo_sites/:id
```

| 属性 | 型    | 必須 | 説明             |
|-----------|---------|----------|-------------------------|
| `id`      | 整数 | はい      | GeoサイトのID。 |

## Geoサイトの修復 {#repair-a-geo-site}

プライマリまたはセカンダリのGeoサイト間でOAuthの同期に問題が発生した場合に、GeoサイトのOAuth認証を修復します。その場合、次のメッセージが表示されることがあります:

```plaintext
There are no OAuth application defined for this Geo node.
```

```plaintext
POST /geo_sites/:id/repair
```

レスポンス例:

```json
{
  "id": 1,
  "name": "us-site",
  "url": "https://primary.example.com/",
  "internal_url": "https://primary.example.com/",
  "primary": true,
  "enabled": true,
  "current": true,
  "files_max_capacity": 10,
  "repos_max_capacity": 25,
  "verification_max_capacity": 100,
  "container_repositories_max_capacity": 10,
  "web_edit_url": "https://primary.example.com/admin/geo/sites/1/edit",
  "_links": {
    "self": "https://primary.example.com/api/v4/geo_sites/1",
    "status":"https://primary.example.com/api/v4/geo_sites/1/status",
    "repair":"https://primary.example.com/api/v4/geo_sites/1/repair"
  }
}
```

## すべてのGeoサイトに関するステータスを取得する {#retrieve-status-about-all-geo-sites}

```plaintext
GET /geo_sites/status
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/geo_sites/status"
```

レスポンス例:

```json
[
  {
    "geo_node_id": 1,
    "projects_count": null,
    "container_repositories_replication_enabled": null,
    "ci_secure_files_count": 0,
    "ci_secure_files_checksum_total_count": 0,
    "ci_secure_files_checksummed_count": 0,
    "ci_secure_files_checksum_failed_count": 0,
    "ci_secure_files_synced_count": null,
    "ci_secure_files_failed_count": null,
    "ci_secure_files_registry_count": null,
    "ci_secure_files_verification_total_count": null,
    "ci_secure_files_verified_count": null,
    "ci_secure_files_verification_failed_count": null,
    "container_repositories_count": 0,
    "container_repositories_checksum_total_count": 0,
    "container_repositories_checksummed_count": 0,
    "container_repositories_checksum_failed_count": 0,
    "container_repositories_synced_count": null,
    "container_repositories_failed_count": null,
    "container_repositories_registry_count": null,
    "container_repositories_verification_total_count": null,
    "container_repositories_verified_count": null,
    "container_repositories_verification_failed_count": null,
    "dependency_proxy_blobs_count": 0,
    "dependency_proxy_blobs_checksum_total_count": 0,
    "dependency_proxy_blobs_checksummed_count": 0,
    "dependency_proxy_blobs_checksum_failed_count": 0,
    "dependency_proxy_blobs_synced_count": null,
    "dependency_proxy_blobs_failed_count": null,
    "dependency_proxy_blobs_registry_count": null,
    "dependency_proxy_blobs_verification_total_count": null,
    "dependency_proxy_blobs_verified_count": null,
    "dependency_proxy_blobs_verification_failed_count": null,
    "dependency_proxy_manifests_count": 0,
    "dependency_proxy_manifests_checksum_total_count": 0,
    "dependency_proxy_manifests_checksummed_count": 0,
    "dependency_proxy_manifests_checksum_failed_count": 0,
    "dependency_proxy_manifests_synced_count": null,
    "dependency_proxy_manifests_failed_count": null,
    "dependency_proxy_manifests_registry_count": null,
    "dependency_proxy_manifests_verification_total_count": null,
    "dependency_proxy_manifests_verified_count": null,
    "dependency_proxy_manifests_verification_failed_count": null,
    "design_management_repositories_count": 0,
    "design_management_repositories_checksum_total_count": 0,
    "design_management_repositories_checksummed_count": 0,
    "design_management_repositories_checksum_failed_count": 0,
    "design_management_repositories_synced_count": null,
    "design_management_repositories_failed_count": null,
    "design_management_repositories_registry_count": null,
    "design_management_repositories_verification_total_count": null,
    "design_management_repositories_verified_count": null,
    "design_management_repositories_verification_failed_count": null,
    "group_wiki_repositories_count": 0,
    "group_wiki_repositories_checksum_total_count": 0,
    "group_wiki_repositories_checksummed_count": 0,
    "group_wiki_repositories_checksum_failed_count": 0,
    "group_wiki_repositories_synced_count": null,
    "group_wiki_repositories_failed_count": null,
    "group_wiki_repositories_registry_count": null,
    "group_wiki_repositories_verification_total_count": null,
    "group_wiki_repositories_verified_count": null,
    "group_wiki_repositories_verification_failed_count": null,
    "job_artifacts_count": 100,
    "job_artifacts_checksum_total_count": 100,
    "job_artifacts_checksummed_count": 100,
    "job_artifacts_checksum_failed_count": 0,
    "job_artifacts_synced_count": null,
    "job_artifacts_failed_count": null,
    "job_artifacts_registry_count": null,
    "job_artifacts_verification_total_count": null,
    "job_artifacts_verified_count": null,
    "job_artifacts_verification_failed_count": null,
    "lfs_objects_count": 9,
    "lfs_objects_checksum_total_count": 9,
    "lfs_objects_checksummed_count": 9,
    "lfs_objects_checksum_failed_count": 0,
    "lfs_objects_synced_count": null,
    "lfs_objects_failed_count": null,
    "lfs_objects_registry_count": null,
    "lfs_objects_verification_total_count": null,
    "lfs_objects_verified_count": null,
    "lfs_objects_verification_failed_count": null,
    "merge_request_diffs_count": 0,
    "merge_request_diffs_checksum_total_count": 0,
    "merge_request_diffs_checksummed_count": 0,
    "merge_request_diffs_checksum_failed_count": 0,
    "merge_request_diffs_synced_count": null,
    "merge_request_diffs_failed_count": null,
    "merge_request_diffs_registry_count": null,
    "merge_request_diffs_verification_total_count": null,
    "merge_request_diffs_verified_count": null,
    "merge_request_diffs_verification_failed_count": null,
    "package_files_count": 25,
    "package_files_checksum_total_count": 25,
    "package_files_checksummed_count": 25,
    "package_files_checksum_failed_count": 0,
    "package_files_synced_count": null,
    "package_files_failed_count": null,
    "package_files_registry_count": null,
    "package_files_verification_total_count": null,
    "package_files_verified_count": null,
    "package_files_verification_failed_count": null,
    "pages_deployments_count": 0,
    "pages_deployments_checksum_total_count": 0,
    "pages_deployments_checksummed_count": 0,
    "pages_deployments_checksum_failed_count": 0,
    "pages_deployments_synced_count": null,
    "pages_deployments_failed_count": null,
    "pages_deployments_registry_count": null,
    "pages_deployments_verification_total_count": null,
    "pages_deployments_verified_count": null,
    "pages_deployments_verification_failed_count": null,
    "pipeline_artifacts_count": 0,
    "pipeline_artifacts_checksum_total_count": 0,
    "pipeline_artifacts_checksummed_count": 0,
    "pipeline_artifacts_checksum_failed_count": 0,
    "pipeline_artifacts_synced_count": null,
    "pipeline_artifacts_failed_count": null,
    "pipeline_artifacts_registry_count": null,
    "pipeline_artifacts_verification_total_count": null,
    "pipeline_artifacts_verified_count": null,
    "pipeline_artifacts_verification_failed_count": null,
    "project_repositories_count": 19,
    "project_repositories_checksum_total_count": 19,
    "project_repositories_checksummed_count": 19,
    "project_repositories_checksum_failed_count": 0,
    "project_repositories_synced_count": null,
    "project_repositories_failed_count": null,
    "project_repositories_registry_count": null,
    "project_repositories_verification_total_count": null,
    "project_repositories_verified_count": null,
    "project_repositories_verification_failed_count": null,
    "project_wiki_repositories_count": 19,
    "project_wiki_repositories_checksum_total_count": 19,
    "project_wiki_repositories_checksummed_count": 19,
    "project_wiki_repositories_checksum_failed_count": 0,
    "project_wiki_repositories_synced_count": null,
    "project_wiki_repositories_failed_count": null,
    "project_wiki_repositories_registry_count": null,
    "project_wiki_repositories_verification_total_count": null,
    "project_wiki_repositories_verified_count": null,
    "project_wiki_repositories_verification_failed_count": null,
    "snippet_repositories_count": 20,
    "snippet_repositories_checksum_total_count": 20,
    "snippet_repositories_checksummed_count": 20,
    "snippet_repositories_checksum_failed_count": 0,
    "snippet_repositories_synced_count": null,
    "snippet_repositories_failed_count": null,
    "snippet_repositories_registry_count": null,
    "snippet_repositories_verification_total_count": null,
    "snippet_repositories_verified_count": null,
    "snippet_repositories_verification_failed_count": null,
    "terraform_state_versions_count": 18,
    "terraform_state_versions_checksum_total_count": 18,
    "terraform_state_versions_checksummed_count": 18,
    "terraform_state_versions_checksum_failed_count": 0,
    "terraform_state_versions_synced_count": null,
    "terraform_state_versions_failed_count": null,
    "terraform_state_versions_registry_count": null,
    "terraform_state_versions_verification_total_count": null,
    "terraform_state_versions_verified_count": null,
    "terraform_state_versions_verification_failed_count": null,
    "uploads_count": 55,
    "uploads_checksum_total_count": 55,
    "uploads_checksummed_count": 55,
    "uploads_checksum_failed_count": 0,
    "uploads_synced_count": null,
    "uploads_failed_count": null,
    "uploads_registry_count": null,
    "uploads_verification_total_count": null,
    "uploads_verified_count": null,
    "uploads_verification_failed_count": null,
    "git_fetch_event_count_weekly": null,
    "git_push_event_count_weekly": null,
    "proxy_remote_requests_event_count_weekly": null,
    "proxy_local_requests_event_count_weekly": null,
    "repositories_checked_in_percentage": "0.00%",
    "replication_slots_used_in_percentage": "100.00%",
    "ci_secure_files_synced_in_percentage": "0.00%",
    "ci_secure_files_verified_in_percentage": "0.00%",
    "container_repositories_synced_in_percentage": "0.00%",
    "container_repositories_verified_in_percentage": "0.00%",
    "dependency_proxy_blobs_synced_in_percentage": "0.00%",
    "dependency_proxy_blobs_verified_in_percentage": "0.00%",
    "dependency_proxy_manifests_synced_in_percentage": "0.00%",
    "dependency_proxy_manifests_verified_in_percentage": "0.00%",
    "design_management_repositories_synced_in_percentage": "0.00%",
    "design_management_repositories_verified_in_percentage": "0.00%",
    "group_wiki_repositories_synced_in_percentage": "0.00%",
    "group_wiki_repositories_verified_in_percentage": "0.00%",
    "job_artifacts_synced_in_percentage": "0.00%",
    "job_artifacts_verified_in_percentage": "0.00%",
    "lfs_objects_synced_in_percentage": "0.00%",
    "lfs_objects_verified_in_percentage": "0.00%",
    "merge_request_diffs_synced_in_percentage": "0.00%",
    "merge_request_diffs_verified_in_percentage": "0.00%",
    "package_files_synced_in_percentage": "0.00%",
    "package_files_verified_in_percentage": "0.00%",
    "pages_deployments_synced_in_percentage": "0.00%",
    "pages_deployments_verified_in_percentage": "0.00%",
    "pipeline_artifacts_synced_in_percentage": "0.00%",
    "pipeline_artifacts_verified_in_percentage": "0.00%",
    "project_repositories_synced_in_percentage": "0.00%",
    "project_repositories_verified_in_percentage": "0.00%",
    "project_wiki_repositories_synced_in_percentage": "0.00%",
    "project_wiki_repositories_verified_in_percentage": "0.00%",
    "snippet_repositories_synced_in_percentage": "0.00%",
    "snippet_repositories_verified_in_percentage": "0.00%",
    "terraform_state_versions_synced_in_percentage": "0.00%",
    "terraform_state_versions_verified_in_percentage": "0.00%",
    "uploads_synced_in_percentage": "0.00%",
    "uploads_verified_in_percentage": "0.00%",
    "repositories_count": 19,
    "replication_slots_count": 1,
    "replication_slots_used_count": 1,
    "healthy": true,
    "health": "Healthy",
    "health_status": "Healthy",
    "missing_oauth_application": false,
    "db_replication_lag_seconds": null,
    "replication_slots_max_retained_wal_bytes": 0,
    "repositories_checked_count": null,
    "repositories_checked_failed_count": null,
    "last_event_id": 534,
    "last_event_timestamp": 1746370442,
    "cursor_last_event_id": null,
    "cursor_last_event_timestamp": 0,
    "last_successful_status_check_timestamp": 1746469565,
    "version": "18.0.0-pre",
    "revision": "bff6f8c6c04",
    "selective_sync_type": null,
    "namespaces": [],
    "updated_at": "2025-05-05T18:26:07.379Z",
    "storage_shards_match": true,
    "_links": {
        "self": "https://primary.example.com/api/v4/geo_sites/1/status",
        "site": "https://primary.example.com/api/v4/geo_sites/1"
    }
  },
  {
    "geo_node_id": 2,
    "projects_count": null,
    "container_repositories_replication_enabled": true,
    "ci_secure_files_count": 0,
    "ci_secure_files_checksum_total_count": null,
    "ci_secure_files_checksummed_count": null,
    "ci_secure_files_checksum_failed_count": null,
    "ci_secure_files_synced_count": 0,
    "ci_secure_files_failed_count": 0,
    "ci_secure_files_registry_count": 0,
    "ci_secure_files_verification_total_count": 0,
    "ci_secure_files_verified_count": 0,
    "ci_secure_files_verification_failed_count": 0,
    "container_repositories_count": 0,
    "container_repositories_checksum_total_count": null,
    "container_repositories_checksummed_count": null,
    "container_repositories_checksum_failed_count": null,
    "container_repositories_synced_count": 0,
    "container_repositories_failed_count": 0,
    "container_repositories_registry_count": 0,
    "container_repositories_verification_total_count": 0,
    "container_repositories_verified_count": 0,
    "container_repositories_verification_failed_count": 0,
    "dependency_proxy_blobs_count": 0,
    "dependency_proxy_blobs_checksum_total_count": null,
    "dependency_proxy_blobs_checksummed_count": null,
    "dependency_proxy_blobs_checksum_failed_count": null,
    "dependency_proxy_blobs_synced_count": 0,
    "dependency_proxy_blobs_failed_count": 0,
    "dependency_proxy_blobs_registry_count": 0,
    "dependency_proxy_blobs_verification_total_count": 0,
    "dependency_proxy_blobs_verified_count": 0,
    "dependency_proxy_blobs_verification_failed_count": 0,
    "dependency_proxy_manifests_count": 0,
    "dependency_proxy_manifests_checksum_total_count": null,
    "dependency_proxy_manifests_checksummed_count": null,
    "dependency_proxy_manifests_checksum_failed_count": null,
    "dependency_proxy_manifests_synced_count": 0,
    "dependency_proxy_manifests_failed_count": 0,
    "dependency_proxy_manifests_registry_count": 0,
    "dependency_proxy_manifests_verification_total_count": 0,
    "dependency_proxy_manifests_verified_count": 0,
    "dependency_proxy_manifests_verification_failed_count": 0,
    "design_management_repositories_count": 0,
    "design_management_repositories_checksum_total_count": null,
    "design_management_repositories_checksummed_count": null,
    "design_management_repositories_checksum_failed_count": null,
    "design_management_repositories_synced_count": 0,
    "design_management_repositories_failed_count": 0,
    "design_management_repositories_registry_count": 0,
    "design_management_repositories_verification_total_count": 0,
    "design_management_repositories_verified_count": 0,
    "design_management_repositories_verification_failed_count": 0,
    "group_wiki_repositories_count": 0,
    "group_wiki_repositories_checksum_total_count": null,
    "group_wiki_repositories_checksummed_count": null,
    "group_wiki_repositories_checksum_failed_count": null,
    "group_wiki_repositories_synced_count": 0,
    "group_wiki_repositories_failed_count": 0,
    "group_wiki_repositories_registry_count": 0,
    "group_wiki_repositories_verification_total_count": 0,
    "group_wiki_repositories_verified_count": 0,
    "group_wiki_repositories_verification_failed_count": 0,
    "job_artifacts_count": 100,
    "job_artifacts_checksum_total_count": null,
    "job_artifacts_checksummed_count": null,
    "job_artifacts_checksum_failed_count": null,
    "job_artifacts_synced_count": 100,
    "job_artifacts_failed_count": 0,
    "job_artifacts_registry_count": 100,
    "job_artifacts_verification_total_count": 100,
    "job_artifacts_verified_count": 100,
    "job_artifacts_verification_failed_count": 0,
    "lfs_objects_count": 9,
    "lfs_objects_checksum_total_count": null,
    "lfs_objects_checksummed_count": null,
    "lfs_objects_checksum_failed_count": null,
    "lfs_objects_synced_count": 9,
    "lfs_objects_failed_count": 0,
    "lfs_objects_registry_count": 9,
    "lfs_objects_verification_total_count": 9,
    "lfs_objects_verified_count": 9,
    "lfs_objects_verification_failed_count": 0,
    "merge_request_diffs_count": 0,
    "merge_request_diffs_checksum_total_count": null,
    "merge_request_diffs_checksummed_count": null,
    "merge_request_diffs_checksum_failed_count": null,
    "merge_request_diffs_synced_count": 0,
    "merge_request_diffs_failed_count": 0,
    "merge_request_diffs_registry_count": 0,
    "merge_request_diffs_verification_total_count": 0,
    "merge_request_diffs_verified_count": 0,
    "merge_request_diffs_verification_failed_count": 0,
    "package_files_count": 25,
    "package_files_checksum_total_count": null,
    "package_files_checksummed_count": null,
    "package_files_checksum_failed_count": null,
    "package_files_synced_count": 25,
    "package_files_failed_count": 0,
    "package_files_registry_count": 25,
    "package_files_verification_total_count": 25,
    "package_files_verified_count": 25,
    "package_files_verification_failed_count": 0,
    "pages_deployments_count": 0,
    "pages_deployments_checksum_total_count": null,
    "pages_deployments_checksummed_count": null,
    "pages_deployments_checksum_failed_count": null,
    "pages_deployments_synced_count": 0,
    "pages_deployments_failed_count": 0,
    "pages_deployments_registry_count": 0,
    "pages_deployments_verification_total_count": 0,
    "pages_deployments_verified_count": 0,
    "pages_deployments_verification_failed_count": 0,
    "pipeline_artifacts_count": 0,
    "pipeline_artifacts_checksum_total_count": null,
    "pipeline_artifacts_checksummed_count": null,
    "pipeline_artifacts_checksum_failed_count": null,
    "pipeline_artifacts_synced_count": 0,
    "pipeline_artifacts_failed_count": 0,
    "pipeline_artifacts_registry_count": 0,
    "pipeline_artifacts_verification_total_count": 0,
    "pipeline_artifacts_verified_count": 0,
    "pipeline_artifacts_verification_failed_count": 0,
    "project_repositories_count": 19,
    "project_repositories_checksum_total_count": null,
    "project_repositories_checksummed_count": null,
    "project_repositories_checksum_failed_count": null,
    "project_repositories_synced_count": 19,
    "project_repositories_failed_count": 0,
    "project_repositories_registry_count": 19,
    "project_repositories_verification_total_count": 19,
    "project_repositories_verified_count": 19,
    "project_repositories_verification_failed_count": 0,
    "project_wiki_repositories_count": 19,
    "project_wiki_repositories_checksum_total_count": null,
    "project_wiki_repositories_checksummed_count": null,
    "project_wiki_repositories_checksum_failed_count": null,
    "project_wiki_repositories_synced_count": 19,
    "project_wiki_repositories_failed_count": 0,
    "project_wiki_repositories_registry_count": 19,
    "project_wiki_repositories_verification_total_count": 19,
    "project_wiki_repositories_verified_count": 19,
    "project_wiki_repositories_verification_failed_count": 0,
    "snippet_repositories_count": 20,
    "snippet_repositories_checksum_total_count": null,
    "snippet_repositories_checksummed_count": null,
    "snippet_repositories_checksum_failed_count": null,
    "snippet_repositories_synced_count": 20,
    "snippet_repositories_failed_count": 0,
    "snippet_repositories_registry_count": 20,
    "snippet_repositories_verification_total_count": 20,
    "snippet_repositories_verified_count": 20,
    "snippet_repositories_verification_failed_count": 0,
    "terraform_state_versions_count": 18,
    "terraform_state_versions_checksum_total_count": null,
    "terraform_state_versions_checksummed_count": null,
    "terraform_state_versions_checksum_failed_count": null,
    "terraform_state_versions_synced_count": 18,
    "terraform_state_versions_failed_count": 0,
    "terraform_state_versions_registry_count": 18,
    "terraform_state_versions_verification_total_count": 18,
    "terraform_state_versions_verified_count": 18,
    "terraform_state_versions_verification_failed_count": 0,
    "uploads_count": 55,
    "uploads_checksum_total_count": null,
    "uploads_checksummed_count": null,
    "uploads_checksum_failed_count": null,
    "uploads_synced_count": 55,
    "uploads_failed_count": 0,
    "uploads_registry_count": 55,
    "uploads_verification_total_count": 55,
    "uploads_verified_count": 55,
    "uploads_verification_failed_count": 0,
    "git_fetch_event_count_weekly": 0,
    "git_push_event_count_weekly": 0,
    "proxy_remote_requests_event_count_weekly": 0,
    "proxy_local_requests_event_count_weekly": 0,
    "repositories_checked_in_percentage": "0.00%",
    "replication_slots_used_in_percentage": "0.00%",
    "ci_secure_files_synced_in_percentage": "0.00%",
    "ci_secure_files_verified_in_percentage": "0.00%",
    "container_repositories_synced_in_percentage": "0.00%",
    "container_repositories_verified_in_percentage": "0.00%",
    "dependency_proxy_blobs_synced_in_percentage": "0.00%",
    "dependency_proxy_blobs_verified_in_percentage": "0.00%",
    "dependency_proxy_manifests_synced_in_percentage": "0.00%",
    "dependency_proxy_manifests_verified_in_percentage": "0.00%",
    "design_management_repositories_synced_in_percentage": "0.00%",
    "design_management_repositories_verified_in_percentage": "0.00%",
    "group_wiki_repositories_synced_in_percentage": "0.00%",
    "group_wiki_repositories_verified_in_percentage": "0.00%",
    "job_artifacts_synced_in_percentage": "100.00%",
    "job_artifacts_verified_in_percentage": "100.00%",
    "lfs_objects_synced_in_percentage": "100.00%",
    "lfs_objects_verified_in_percentage": "100.00%",
    "merge_request_diffs_synced_in_percentage": "0.00%",
    "merge_request_diffs_verified_in_percentage": "0.00%",
    "package_files_synced_in_percentage": "100.00%",
    "package_files_verified_in_percentage": "100.00%",
    "pages_deployments_synced_in_percentage": "0.00%",
    "pages_deployments_verified_in_percentage": "0.00%",
    "pipeline_artifacts_synced_in_percentage": "0.00%",
    "pipeline_artifacts_verified_in_percentage": "0.00%",
    "project_repositories_synced_in_percentage": "100.00%",
    "project_repositories_verified_in_percentage": "100.00%",
    "project_wiki_repositories_synced_in_percentage": "100.00%",
    "project_wiki_repositories_verified_in_percentage": "100.00%",
    "snippet_repositories_synced_in_percentage": "100.00%",
    "snippet_repositories_verified_in_percentage": "100.00%",
    "terraform_state_versions_synced_in_percentage": "100.00%",
    "terraform_state_versions_verified_in_percentage": "100.00%",
    "uploads_synced_in_percentage": "100.00%",
    "uploads_verified_in_percentage": "100.00%",
    "repositories_count": 19,
    "replication_slots_count": null,
    "replication_slots_used_count": null,
    "healthy": true,
    "health": "Healthy",
    "health_status": "Healthy",
    "missing_oauth_application": false,
    "db_replication_lag_seconds": 0,
    "replication_slots_max_retained_wal_bytes": null,
    "repositories_checked_count": null,
    "repositories_checked_failed_count": null,
    "last_event_id": 534,
    "last_event_timestamp": 1746370442,
    "cursor_last_event_id": 534,
    "cursor_last_event_timestamp": 1746370442,
    "last_successful_status_check_timestamp": 1746469624,
    "version": "18.0.0-pre",
    "revision": "60237485299",
    "selective_sync_type": null,
    "namespaces": [],
    "updated_at": "2025-05-05T18:26:05.000Z",
    "storage_shards_match": true,
    "_links": {
        "self": "https://primary.example.com/api/v4/geo_sites/2/status",
        "site": "https://primary.example.com/api/v4/geo_sites/2"
    }
  }
]
```

## 特定のGeoサイトに関するステータスを取得する {#retrieve-status-about-a-specific-geo-site}

```plaintext
GET /geo_sites/:id/status
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/geo_sites/2/status"
```

レスポンス例:

```json
  {
    "geo_node_id": 2,
    "projects_count": null,
    "container_repositories_replication_enabled": true,
    "ci_secure_files_count": 0,
    "ci_secure_files_checksum_total_count": null,
    "ci_secure_files_checksummed_count": null,
    "ci_secure_files_checksum_failed_count": null,
    "ci_secure_files_synced_count": 0,
    "ci_secure_files_failed_count": 0,
    "ci_secure_files_registry_count": 0,
    "ci_secure_files_verification_total_count": 0,
    "ci_secure_files_verified_count": 0,
    "ci_secure_files_verification_failed_count": 0,
    "container_repositories_count": 0,
    "container_repositories_checksum_total_count": null,
    "container_repositories_checksummed_count": null,
    "container_repositories_checksum_failed_count": null,
    "container_repositories_synced_count": 0,
    "container_repositories_failed_count": 0,
    "container_repositories_registry_count": 0,
    "container_repositories_verification_total_count": 0,
    "container_repositories_verified_count": 0,
    "container_repositories_verification_failed_count": 0,
    "dependency_proxy_blobs_count": 0,
    "dependency_proxy_blobs_checksum_total_count": null,
    "dependency_proxy_blobs_checksummed_count": null,
    "dependency_proxy_blobs_checksum_failed_count": null,
    "dependency_proxy_blobs_synced_count": 0,
    "dependency_proxy_blobs_failed_count": 0,
    "dependency_proxy_blobs_registry_count": 0,
    "dependency_proxy_blobs_verification_total_count": 0,
    "dependency_proxy_blobs_verified_count": 0,
    "dependency_proxy_blobs_verification_failed_count": 0,
    "dependency_proxy_manifests_count": 0,
    "dependency_proxy_manifests_checksum_total_count": null,
    "dependency_proxy_manifests_checksummed_count": null,
    "dependency_proxy_manifests_checksum_failed_count": null,
    "dependency_proxy_manifests_synced_count": 0,
    "dependency_proxy_manifests_failed_count": 0,
    "dependency_proxy_manifests_registry_count": 0,
    "dependency_proxy_manifests_verification_total_count": 0,
    "dependency_proxy_manifests_verified_count": 0,
    "dependency_proxy_manifests_verification_failed_count": 0,
    "design_management_repositories_count": 0,
    "design_management_repositories_checksum_total_count": null,
    "design_management_repositories_checksummed_count": null,
    "design_management_repositories_checksum_failed_count": null,
    "design_management_repositories_synced_count": 0,
    "design_management_repositories_failed_count": 0,
    "design_management_repositories_registry_count": 0,
    "design_management_repositories_verification_total_count": 0,
    "design_management_repositories_verified_count": 0,
    "design_management_repositories_verification_failed_count": 0,
    "group_wiki_repositories_count": 0,
    "group_wiki_repositories_checksum_total_count": null,
    "group_wiki_repositories_checksummed_count": null,
    "group_wiki_repositories_checksum_failed_count": null,
    "group_wiki_repositories_synced_count": 0,
    "group_wiki_repositories_failed_count": 0,
    "group_wiki_repositories_registry_count": 0,
    "group_wiki_repositories_verification_total_count": 0,
    "group_wiki_repositories_verified_count": 0,
    "group_wiki_repositories_verification_failed_count": 0,
    "job_artifacts_count": 100,
    "job_artifacts_checksum_total_count": null,
    "job_artifacts_checksummed_count": null,
    "job_artifacts_checksum_failed_count": null,
    "job_artifacts_synced_count": 100,
    "job_artifacts_failed_count": 0,
    "job_artifacts_registry_count": 100,
    "job_artifacts_verification_total_count": 100,
    "job_artifacts_verified_count": 100,
    "job_artifacts_verification_failed_count": 0,
    "lfs_objects_count": 9,
    "lfs_objects_checksum_total_count": null,
    "lfs_objects_checksummed_count": null,
    "lfs_objects_checksum_failed_count": null,
    "lfs_objects_synced_count": 9,
    "lfs_objects_failed_count": 0,
    "lfs_objects_registry_count": 9,
    "lfs_objects_verification_total_count": 9,
    "lfs_objects_verified_count": 9,
    "lfs_objects_verification_failed_count": 0,
    "merge_request_diffs_count": 0,
    "merge_request_diffs_checksum_total_count": null,
    "merge_request_diffs_checksummed_count": null,
    "merge_request_diffs_checksum_failed_count": null,
    "merge_request_diffs_synced_count": 0,
    "merge_request_diffs_failed_count": 0,
    "merge_request_diffs_registry_count": 0,
    "merge_request_diffs_verification_total_count": 0,
    "merge_request_diffs_verified_count": 0,
    "merge_request_diffs_verification_failed_count": 0,
    "package_files_count": 25,
    "package_files_checksum_total_count": null,
    "package_files_checksummed_count": null,
    "package_files_checksum_failed_count": null,
    "package_files_synced_count": 25,
    "package_files_failed_count": 0,
    "package_files_registry_count": 25,
    "package_files_verification_total_count": 25,
    "package_files_verified_count": 25,
    "package_files_verification_failed_count": 0,
    "pages_deployments_count": 0,
    "pages_deployments_checksum_total_count": null,
    "pages_deployments_checksummed_count": null,
    "pages_deployments_checksum_failed_count": null,
    "pages_deployments_synced_count": 0,
    "pages_deployments_failed_count": 0,
    "pages_deployments_registry_count": 0,
    "pages_deployments_verification_total_count": 0,
    "pages_deployments_verified_count": 0,
    "pages_deployments_verification_failed_count": 0,
    "pipeline_artifacts_count": 0,
    "pipeline_artifacts_checksum_total_count": null,
    "pipeline_artifacts_checksummed_count": null,
    "pipeline_artifacts_checksum_failed_count": null,
    "pipeline_artifacts_synced_count": 0,
    "pipeline_artifacts_failed_count": 0,
    "pipeline_artifacts_registry_count": 0,
    "pipeline_artifacts_verification_total_count": 0,
    "pipeline_artifacts_verified_count": 0,
    "pipeline_artifacts_verification_failed_count": 0,
    "project_repositories_count": 19,
    "project_repositories_checksum_total_count": null,
    "project_repositories_checksummed_count": null,
    "project_repositories_checksum_failed_count": null,
    "project_repositories_synced_count": 19,
    "project_repositories_failed_count": 0,
    "project_repositories_registry_count": 19,
    "project_repositories_verification_total_count": 19,
    "project_repositories_verified_count": 19,
    "project_repositories_verification_failed_count": 0,
    "project_wiki_repositories_count": 19,
    "project_wiki_repositories_checksum_total_count": null,
    "project_wiki_repositories_checksummed_count": null,
    "project_wiki_repositories_checksum_failed_count": null,
    "project_wiki_repositories_synced_count": 19,
    "project_wiki_repositories_failed_count": 0,
    "project_wiki_repositories_registry_count": 19,
    "project_wiki_repositories_verification_total_count": 19,
    "project_wiki_repositories_verified_count": 19,
    "project_wiki_repositories_verification_failed_count": 0,
    "snippet_repositories_count": 20,
    "snippet_repositories_checksum_total_count": null,
    "snippet_repositories_checksummed_count": null,
    "snippet_repositories_checksum_failed_count": null,
    "snippet_repositories_synced_count": 20,
    "snippet_repositories_failed_count": 0,
    "snippet_repositories_registry_count": 20,
    "snippet_repositories_verification_total_count": 20,
    "snippet_repositories_verified_count": 20,
    "snippet_repositories_verification_failed_count": 0,
    "terraform_state_versions_count": 18,
    "terraform_state_versions_checksum_total_count": null,
    "terraform_state_versions_checksummed_count": null,
    "terraform_state_versions_checksum_failed_count": null,
    "terraform_state_versions_synced_count": 18,
    "terraform_state_versions_failed_count": 0,
    "terraform_state_versions_registry_count": 18,
    "terraform_state_versions_verification_total_count": 18,
    "terraform_state_versions_verified_count": 18,
    "terraform_state_versions_verification_failed_count": 0,
    "uploads_count": 55,
    "uploads_checksum_total_count": null,
    "uploads_checksummed_count": null,
    "uploads_checksum_failed_count": null,
    "uploads_synced_count": 55,
    "uploads_failed_count": 0,
    "uploads_registry_count": 55,
    "uploads_verification_total_count": 55,
    "uploads_verified_count": 55,
    "uploads_verification_failed_count": 0,
    "git_fetch_event_count_weekly": 0,
    "git_push_event_count_weekly": 0,
    "proxy_remote_requests_event_count_weekly": 0,
    "proxy_local_requests_event_count_weekly": 0,
    "repositories_checked_in_percentage": "0.00%",
    "replication_slots_used_in_percentage": "0.00%",
    "ci_secure_files_synced_in_percentage": "0.00%",
    "ci_secure_files_verified_in_percentage": "0.00%",
    "container_repositories_synced_in_percentage": "0.00%",
    "container_repositories_verified_in_percentage": "0.00%",
    "dependency_proxy_blobs_synced_in_percentage": "0.00%",
    "dependency_proxy_blobs_verified_in_percentage": "0.00%",
    "dependency_proxy_manifests_synced_in_percentage": "0.00%",
    "dependency_proxy_manifests_verified_in_percentage": "0.00%",
    "design_management_repositories_synced_in_percentage": "0.00%",
    "design_management_repositories_verified_in_percentage": "0.00%",
    "group_wiki_repositories_synced_in_percentage": "0.00%",
    "group_wiki_repositories_verified_in_percentage": "0.00%",
    "job_artifacts_synced_in_percentage": "100.00%",
    "job_artifacts_verified_in_percentage": "100.00%",
    "lfs_objects_synced_in_percentage": "100.00%",
    "lfs_objects_verified_in_percentage": "100.00%",
    "merge_request_diffs_synced_in_percentage": "0.00%",
    "merge_request_diffs_verified_in_percentage": "0.00%",
    "package_files_synced_in_percentage": "100.00%",
    "package_files_verified_in_percentage": "100.00%",
    "pages_deployments_synced_in_percentage": "0.00%",
    "pages_deployments_verified_in_percentage": "0.00%",
    "pipeline_artifacts_synced_in_percentage": "0.00%",
    "pipeline_artifacts_verified_in_percentage": "0.00%",
    "project_repositories_synced_in_percentage": "100.00%",
    "project_repositories_verified_in_percentage": "100.00%",
    "project_wiki_repositories_synced_in_percentage": "100.00%",
    "project_wiki_repositories_verified_in_percentage": "100.00%",
    "snippet_repositories_synced_in_percentage": "100.00%",
    "snippet_repositories_verified_in_percentage": "100.00%",
    "terraform_state_versions_synced_in_percentage": "100.00%",
    "terraform_state_versions_verified_in_percentage": "100.00%",
    "uploads_synced_in_percentage": "100.00%",
    "uploads_verified_in_percentage": "100.00%",
    "repositories_count": 19,
    "replication_slots_count": null,
    "replication_slots_used_count": null,
    "healthy": true,
    "health": "Healthy",
    "health_status": "Healthy",
    "missing_oauth_application": false,
    "db_replication_lag_seconds": 0,
    "replication_slots_max_retained_wal_bytes": null,
    "repositories_checked_count": null,
    "repositories_checked_failed_count": null,
    "last_event_id": 534,
    "last_event_timestamp": 1746370442,
    "cursor_last_event_id": 534,
    "cursor_last_event_timestamp": 1746370442,
    "last_successful_status_check_timestamp": 1746469624,
    "version": "18.0.0-pre",
    "revision": "60237485299",
    "selective_sync_type": null,
    "namespaces": [],
    "updated_at": "2025-05-05T18:26:05.000Z",
    "storage_shards_match": true,
    "_links": {
        "self": "https://primary.example.com/api/v4/geo_sites/2/status",
        "site": "https://primary.example.com/api/v4/geo_sites/2"
    }
  }
```

{{< alert type="note" >}}

`health_status`パラメータは「Healthy」または「Unhealthy」状態でのみ可能ですが、`health`パラメータは空、「Healthy」、または実際のエラーメッセージを含むことができます。

{{< /alert >}}
