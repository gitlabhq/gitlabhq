---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Geo sites API
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/369140) in GitLab 16.0.

Use the Geo sites API to manage Geo site endpoints.

Prerequisites:

- You must be an administrator.

## Create a new Geo site

Creates a new Geo site.

```plaintext
POST /geo_sites
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/geo_sites" \
     --request POST \
     -d "name=himynameissomething" \
     -d "url=https://another-node.example.com/"
```

| Attribute                             | Type    | Required | Description                                                                                                                                            |
|---------------------------------------|---------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| `primary`                             | boolean | no       | Specifying whether this site should be primary. Defaults to false.                                                                                     |
| `enabled`                             | boolean | no       | Flag indicating if the Geo site is enabled. Defaults to true.                                                                                          |
| `name`                                | string  | yes      | The unique identifier for the Geo site. Must match `geo_node_name` if it is set in `gitlab.rb`, otherwise it must match `external_url`                 |
| `url`                                 | string  | yes      | The user-facing URL for the Geo site.                                                                                                                  |
| `internal_url`                        | string  | no       | The URL defined on the primary site that secondary sites should use to contact it. Returns `url` if not set.                                           |
| `files_max_capacity`                  | integer | no       | Control the maximum concurrency of LFS/attachment backfill for this secondary site. Defaults to 10.                                                    |
| `repos_max_capacity`                  | integer | no       | Control the maximum concurrency of repository backfill for this secondary site. Defaults to 25.                                                        |
| `verification_max_capacity`           | integer | no       | Control the maximum concurrency of repository verification for this site. Defaults to 100.                                                             |
| `container_repositories_max_capacity` | integer | no       | Control the maximum concurrency of container repository sync for this site. Defaults to 10.                                                            |
| `sync_object_storage`                 | boolean | no       | Flag indicating if the secondary Geo site should replicate blobs in Object Storage. Defaults to false.                                                 |
| `selective_sync_type`                 | string  | no       | Limit syncing to only specific groups or shards. Valid values: `"namespaces"`, `"shards"`, or `null`.                                                  |
| `selective_sync_shards`               | array   | no       | The repository storage for the projects synced if `selective_sync_type` == `shards`.                                                                   |
| `selective_sync_namespace_ids`        | array   | no       | The IDs of groups that should be synced, if `selective_sync_type` == `namespaces`.                                                                     |
| `minimum_reverification_interval`     | integer | no       | The interval (in days) in which the repository verification is valid. Once expired, it is reverified. This has no effect when set on a secondary site. |

Example response:

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

## Retrieve configuration about all Geo sites

```plaintext
GET /geo_sites
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/geo_sites"
```

Example response:

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

## Retrieve configuration about a specific Geo site

```plaintext
GET /geo_sites/:id
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/geo_sites/1"
```

Example response:

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

## Edit a Geo site

Updates settings of an existing Geo site.

```plaintext
PUT /geo_sites/:id
```

| Attribute                             | Type    | Required | Description                                                                                                                                            |
|---------------------------------------|---------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`                                  | integer | yes      | The ID of the Geo site.                                                                                                                                |
| `enabled`                             | boolean | no       | Flag indicating if the Geo site is enabled.                                                                                                            |
| `name`                                | string  | no       | The unique identifier for the Geo site. Must match `geo_node_name` if it is set in `gitlab.rb`, otherwise it must match `external_url`.                |
| `url`                                 | string  | no       | The user-facing URL of the Geo site.                                                                                                                   |
| `internal_url`                        | string  | no       | The URL defined on the primary site that secondary sites should use to contact it. Returns `url` if not set.                                           |
| `files_max_capacity`                  | integer | no       | Control the maximum concurrency of LFS/attachment backfill for this secondary site.                                                                    |
| `repos_max_capacity`                  | integer | no       | Control the maximum concurrency of repository backfill for this secondary site.                                                                        |
| `verification_max_capacity`           | integer | no       | Control the maximum concurrency of verification for this site.                                                                                         |
| `container_repositories_max_capacity` | integer | no       | Control the maximum concurrency of container repository sync for this site.                                                                            |
| `selective_sync_type`                 | string  | no       | Limit syncing to only specific groups or shards. Valid values: `"namespaces"`, `"shards"`, or `null`.                                                  |
| `selective_sync_shards`               | array   | no       | The repository storage for the projects synced if `selective_sync_type` == `shards`.                                                                   |
| `selective_sync_namespace_ids`        | array   | no       | The IDs of groups that should be synced, if `selective_sync_type` == `namespaces`.                                                                     |
| `minimum_reverification_interval`     | integer | no       | The interval (in days) in which the repository verification is valid. Once expired, it is reverified. This has no effect when set on a secondary site. |

Example response:

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

## Delete a Geo site

Removes the Geo site.

```plaintext
DELETE /geo_sites/:id
```

| Attribute | Type    | Required | Description             |
|-----------|---------|----------|-------------------------|
| `id`      | integer | yes      | The ID of the Geo site. |

## Repair a Geo site

Repairs the OAuth authentication of a Geo site in the event that there is an
OAuth synchronization problem between the primary or secondary Geo sites.
In that case, this message may be displayed:

```plaintext
There are no OAuth application defined for this Geo node.
```

```plaintext
POST /geo_sites/:id/repair
```

Example response:

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

## Retrieve status about all Geo sites

```plaintext
GET /geo_sites/status
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/geo_sites/status"
```

Example response:

```json
[
  {
    "geo_node_id": 1,
    "projects_count": 19,
    "container_repositories_replication_enabled": null,
    "lfs_objects_count": 0,
    "lfs_objects_checksum_total_count": 0,
    "lfs_objects_checksummed_count": 0,
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
    "group_wiki_repositories_count": 0,
    "group_wiki_repositories_checksum_total_count": null,
    "group_wiki_repositories_checksummed_count": null,
    "group_wiki_repositories_checksum_failed_count": null,
    "group_wiki_repositories_synced_count": null,
    "group_wiki_repositories_failed_count": null,
    "group_wiki_repositories_registry_count": null,
    "group_wiki_repositories_verification_total_count": null,
    "group_wiki_repositories_verified_count": null,
    "group_wiki_repositories_verification_failed_count": null,
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
    "uploads_count": 51,
    "uploads_checksum_total_count": 51,
    "uploads_checksummed_count": 51,
    "uploads_checksum_failed_count": 0,
    "uploads_synced_count": null,
    "uploads_failed_count": null,
    "uploads_registry_count": null,
    "uploads_verification_total_count": null,
    "uploads_verified_count": null,
    "uploads_verification_failed_count": null,
    "job_artifacts_count": 205,
    "job_artifacts_checksum_total_count": 205,
    "job_artifacts_checksummed_count": 205,
    "job_artifacts_checksum_failed_count": 0,
    "job_artifacts_synced_count": null,
    "job_artifacts_failed_count": null,
    "job_artifacts_registry_count": null,
    "job_artifacts_verification_total_count": null,
    "job_artifacts_verified_count": null,
    "job_artifacts_verification_failed_count": null,
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
    "git_fetch_event_count_weekly": null,
    "git_push_event_count_weekly": null,
    "proxy_remote_requests_event_count_weekly": null,
    "proxy_local_requests_event_count_weekly": null,
    "repositories_checked_in_percentage": "0.00%",
    "replication_slots_used_in_percentage": "100.00%",
    "lfs_objects_synced_in_percentage": "0.00%",
    "lfs_objects_verified_in_percentage": "0.00%",
    "merge_request_diffs_synced_in_percentage": "0.00%",
    "merge_request_diffs_verified_in_percentage": "0.00%",
    "package_files_synced_in_percentage": "0.00%",
    "package_files_verified_in_percentage": "0.00%",
    "terraform_state_versions_synced_in_percentage": "0.00%",
    "terraform_state_versions_verified_in_percentage": "0.00%",
    "snippet_repositories_synced_in_percentage": "0.00%",
    "snippet_repositories_verified_in_percentage": "0.00%",
    "group_wiki_repositories_synced_in_percentage": "0.00%",
    "group_wiki_repositories_verified_in_percentage": "0.00%",
    "pipeline_artifacts_synced_in_percentage": "0.00%",
    "pipeline_artifacts_verified_in_percentage": "0.00%",
    "pages_deployments_synced_in_percentage": "0.00%",
    "pages_deployments_verified_in_percentage": "0.00%",
    "uploads_synced_in_percentage": "0.00%",
    "uploads_verified_in_percentage": "0.00%",
    "job_artifacts_synced_in_percentage": "0.00%",
    "job_artifacts_verified_in_percentage": "0.00%",
    "ci_secure_files_synced_in_percentage": "0.00%",
    "ci_secure_files_verified_in_percentage": "0.00%",
    "container_repositories_synced_in_percentage": "0.00%",
    "container_repositories_verified_in_percentage": "0.00%",
    "dependency_proxy_blobs_synced_in_percentage": "0.00%",
    "dependency_proxy_blobs_verified_in_percentage": "0.00%",
    "dependency_proxy_manifests_synced_in_percentage": "0.00%",
    "dependency_proxy_manifests_verified_in_percentage": "0.00%",
    "project_wiki_repositories_synced_in_percentage": "0.00%",
    "project_wiki_repositories_verified_in_percentage": "0.00%",
    "projects_count": 19,
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
    "last_event_id": 357,
    "last_event_timestamp": 1683127088,
    "cursor_last_event_id": null,
    "cursor_last_event_timestamp": 0,
    "last_successful_status_check_timestamp": 1683129788,
    "version": "16.0.0-pre",
    "revision": "129eb954664",
    "selective_sync_type": null,
    "namespaces": [],
    "updated_at": "2023-05-03T16:03:10.117Z",
    "storage_shards_match": true,
    "_links": {
      "self": "https://primary.example.com/api/v4/geo_sites/1/status",
      "site": "https://primary.example.com/api/v4/geo_sites/1"
    }
  },
  {
    "geo_node_id": 2,
    "projects_count": 19,
    "container_repositories_replication_enabled": null,
    "lfs_objects_count": 0,
    "lfs_objects_checksum_total_count": null,
    "lfs_objects_checksummed_count": null,
    "lfs_objects_checksum_failed_count": null,
    "lfs_objects_synced_count": 0,
    "lfs_objects_failed_count": 0,
    "lfs_objects_registry_count": 0,
    "lfs_objects_verification_total_count": 0,
    "lfs_objects_verified_count": 0,
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
    "package_files_synced_count": 1,
    "package_files_failed_count": 24,
    "package_files_registry_count": 25,
    "package_files_verification_total_count": 1,
    "package_files_verified_count": 1,
    "package_files_verification_failed_count": 0,
    "terraform_state_versions_count": 18,
    "terraform_state_versions_checksum_total_count": null,
    "terraform_state_versions_checksummed_count": null,
    "terraform_state_versions_checksum_failed_count": null,
    "terraform_state_versions_synced_count": 0,
    "terraform_state_versions_failed_count": 0,
    "terraform_state_versions_registry_count": 18,
    "terraform_state_versions_verification_total_count": 0,
    "terraform_state_versions_verified_count": 0,
    "terraform_state_versions_verification_failed_count": 0,
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
    "group_wiki_repositories_count": 0,
    "group_wiki_repositories_checksum_total_count": null,
    "group_wiki_repositories_checksummed_count": null,
    "group_wiki_repositories_checksum_failed_count": null,
    "group_wiki_repositories_synced_count": 0,
    "group_wiki_repositories_failed_count": 0,
    "group_wiki_repositories_registry_count": 0,
    "group_wiki_repositories_verification_total_count": null,
    "group_wiki_repositories_verified_count": null,
    "group_wiki_repositories_verification_failed_count": null,
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
    "uploads_count": 51,
    "uploads_checksum_total_count": null,
    "uploads_checksummed_count": null,
    "uploads_checksum_failed_count": null,
    "uploads_synced_count": 0,
    "uploads_failed_count": 1,
    "uploads_registry_count": 51,
    "uploads_verification_total_count": 0,
    "uploads_verified_count": 0,
    "uploads_verification_failed_count": 0,
    "job_artifacts_count": 0,
    "job_artifacts_checksum_total_count": null,
    "job_artifacts_checksummed_count": null,
    "job_artifacts_checksum_failed_count": null,
    "job_artifacts_synced_count": 0,
    "job_artifacts_failed_count": 0,
    "job_artifacts_registry_count": 0,
    "job_artifacts_verification_total_count": 0,
    "job_artifacts_verified_count": 0,
    "job_artifacts_verification_failed_count": 0,
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
    "container_repositories_count": null,
    "container_repositories_checksum_total_count": null,
    "container_repositories_checksummed_count": null,
    "container_repositories_checksum_failed_count": null,
    "container_repositories_synced_count": null,
    "container_repositories_failed_count": null,
    "container_repositories_registry_count": null,
    "container_repositories_verification_total_count": null,
    "container_repositories_verified_count": null,
    "container_repositories_verification_failed_count": null,
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
    "git_fetch_event_count_weekly": null,
    "git_push_event_count_weekly": null,
    "proxy_remote_requests_event_count_weekly": null,
    "proxy_local_requests_event_count_weekly": null,
    "repositories_checked_in_percentage": "0.00%",
    "replication_slots_used_in_percentage": "0.00%",
    "lfs_objects_synced_in_percentage": "0.00%",
    "lfs_objects_verified_in_percentage": "0.00%",
    "merge_request_diffs_synced_in_percentage": "0.00%",
    "merge_request_diffs_verified_in_percentage": "0.00%",
    "package_files_synced_in_percentage": "4.00%",
    "package_files_verified_in_percentage": "4.00%",
    "terraform_state_versions_synced_in_percentage": "0.00%",
    "terraform_state_versions_verified_in_percentage": "0.00%",
    "snippet_repositories_synced_in_percentage": "100.00%",
    "snippet_repositories_verified_in_percentage": "100.00%",
    "group_wiki_repositories_synced_in_percentage": "0.00%",
    "group_wiki_repositories_verified_in_percentage": "0.00%",
    "pipeline_artifacts_synced_in_percentage": "0.00%",
    "pipeline_artifacts_verified_in_percentage": "0.00%",
    "pages_deployments_synced_in_percentage": "0.00%",
    "pages_deployments_verified_in_percentage": "0.00%",
    "uploads_synced_in_percentage": "0.00%",
    "uploads_verified_in_percentage": "0.00%",
    "job_artifacts_synced_in_percentage": "0.00%",
    "job_artifacts_verified_in_percentage": "0.00%",
    "ci_secure_files_synced_in_percentage": "0.00%",
    "ci_secure_files_verified_in_percentage": "0.00%",
    "container_repositories_synced_in_percentage": "0.00%",
    "container_repositories_verified_in_percentage": "0.00%",
    "dependency_proxy_blobs_synced_in_percentage": "0.00%",
    "dependency_proxy_blobs_verified_in_percentage": "0.00%",
    "dependency_proxy_manifests_synced_in_percentage": "0.00%",
    "dependency_proxy_manifests_verified_in_percentage": "0.00%",
    "project_wiki_repositories_synced_in_percentage": "100.00%",
    "project_wiki_repositories_verified_in_percentage": "100.00%",
    "projects_count": 19,
    "replication_slots_count": null,
    "replication_slots_used_count": null,
    "healthy": false,
    "health": "An existing tracking database cannot be reused..",
    "health_status": "Unhealthy",
    "missing_oauth_application": false,
    "db_replication_lag_seconds": 0,
    "replication_slots_max_retained_wal_bytes": null,
    "repositories_checked_count": null,
    "repositories_checked_failed_count": null,
    "last_event_id": 357,
    "last_event_timestamp": 1683127088,
    "cursor_last_event_id": 357,
    "cursor_last_event_timestamp": 1683127088,
    "last_successful_status_check_timestamp": 1683127146,
    "version": "16.0.0-pre",
    "revision": "129eb954664",
    "selective_sync_type": "",
    "namespaces": [],
    "updated_at": "2023-05-03T15:19:06.174Z",
    "storage_shards_match": true,
    "_links": {
      "self": "https://primary.example.com/api/v4/geo_sites/2/status",
      "site": "https://primary.example.com/api/v4/geo_sites/2"
    }
  }
]
```

## Retrieve status about a specific Geo site

```plaintext
GET /geo_sites/:id/status
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/geo_sites/2/status"
```

Example response:

```json
  {
  "geo_node_id": 2,
  "projects_count": 19,
  "container_repositories_replication_enabled": null,
  "lfs_objects_count": 0,
  "lfs_objects_checksum_total_count": null,
  "lfs_objects_checksummed_count": null,
  "lfs_objects_checksum_failed_count": null,
  "lfs_objects_synced_count": 0,
  "lfs_objects_failed_count": 0,
  "lfs_objects_registry_count": 0,
  "lfs_objects_verification_total_count": 0,
  "lfs_objects_verified_count": 0,
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
  "package_files_synced_count": 1,
  "package_files_failed_count": 24,
  "package_files_registry_count": 25,
  "package_files_verification_total_count": 1,
  "package_files_verified_count": 1,
  "package_files_verification_failed_count": 0,
  "terraform_state_versions_count": 18,
  "terraform_state_versions_checksum_total_count": null,
  "terraform_state_versions_checksummed_count": null,
  "terraform_state_versions_checksum_failed_count": null,
  "terraform_state_versions_synced_count": 0,
  "terraform_state_versions_failed_count": 0,
  "terraform_state_versions_registry_count": 18,
  "terraform_state_versions_verification_total_count": 0,
  "terraform_state_versions_verified_count": 0,
  "terraform_state_versions_verification_failed_count": 0,
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
  "group_wiki_repositories_count": 0,
  "group_wiki_repositories_checksum_total_count": null,
  "group_wiki_repositories_checksummed_count": null,
  "group_wiki_repositories_checksum_failed_count": null,
  "group_wiki_repositories_synced_count": 0,
  "group_wiki_repositories_failed_count": 0,
  "group_wiki_repositories_registry_count": 0,
  "group_wiki_repositories_verification_total_count": null,
  "group_wiki_repositories_verified_count": null,
  "group_wiki_repositories_verification_failed_count": null,
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
  "uploads_count": 51,
  "uploads_checksum_total_count": null,
  "uploads_checksummed_count": null,
  "uploads_checksum_failed_count": null,
  "uploads_synced_count": 0,
  "uploads_failed_count": 1,
  "uploads_registry_count": 51,
  "uploads_verification_total_count": 0,
  "uploads_verified_count": 0,
  "uploads_verification_failed_count": 0,
  "job_artifacts_count": 0,
  "job_artifacts_checksum_total_count": null,
  "job_artifacts_checksummed_count": null,
  "job_artifacts_checksum_failed_count": null,
  "job_artifacts_synced_count": 0,
  "job_artifacts_failed_count": 0,
  "job_artifacts_registry_count": 0,
  "job_artifacts_verification_total_count": 0,
  "job_artifacts_verified_count": 0,
  "job_artifacts_verification_failed_count": 0,
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
  "container_repositories_count": null,
  "container_repositories_checksum_total_count": null,
  "container_repositories_checksummed_count": null,
  "container_repositories_checksum_failed_count": null,
  "container_repositories_synced_count": null,
  "container_repositories_failed_count": null,
  "container_repositories_registry_count": null,
  "container_repositories_verification_total_count": null,
  "container_repositories_verified_count": null,
  "container_repositories_verification_failed_count": null,
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
  "git_fetch_event_count_weekly": null,
  "git_push_event_count_weekly": null,
  "proxy_remote_requests_event_count_weekly": null,
  "proxy_local_requests_event_count_weekly": null,
  "repositories_checked_in_percentage": "0.00%",
  "replication_slots_used_in_percentage": "0.00%",
  "lfs_objects_synced_in_percentage": "0.00%",
  "lfs_objects_verified_in_percentage": "0.00%",
  "merge_request_diffs_synced_in_percentage": "0.00%",
  "merge_request_diffs_verified_in_percentage": "0.00%",
  "package_files_synced_in_percentage": "4.00%",
  "package_files_verified_in_percentage": "4.00%",
  "terraform_state_versions_synced_in_percentage": "0.00%",
  "terraform_state_versions_verified_in_percentage": "0.00%",
  "snippet_repositories_synced_in_percentage": "100.00%",
  "snippet_repositories_verified_in_percentage": "100.00%",
  "group_wiki_repositories_synced_in_percentage": "0.00%",
  "group_wiki_repositories_verified_in_percentage": "0.00%",
  "pipeline_artifacts_synced_in_percentage": "0.00%",
  "pipeline_artifacts_verified_in_percentage": "0.00%",
  "pages_deployments_synced_in_percentage": "0.00%",
  "pages_deployments_verified_in_percentage": "0.00%",
  "uploads_synced_in_percentage": "0.00%",
  "uploads_verified_in_percentage": "0.00%",
  "job_artifacts_synced_in_percentage": "0.00%",
  "job_artifacts_verified_in_percentage": "0.00%",
  "ci_secure_files_synced_in_percentage": "0.00%",
  "ci_secure_files_verified_in_percentage": "0.00%",
  "container_repositories_synced_in_percentage": "0.00%",
  "container_repositories_verified_in_percentage": "0.00%",
  "dependency_proxy_blobs_synced_in_percentage": "0.00%",
  "dependency_proxy_blobs_verified_in_percentage": "0.00%",
  "dependency_proxy_manifests_synced_in_percentage": "0.00%",
  "dependency_proxy_manifests_verified_in_percentage": "0.00%",
  "project_wiki_repositories_synced_in_percentage": "100.00%",
  "project_wiki_repositories_verified_in_percentage": "100.00%",
  "repositories_count": 19,
  "replication_slots_count": null,
  "replication_slots_used_count": null,
  "healthy": false,
  "health": "An existing tracking database cannot be reused..",
  "health_status": "Unhealthy",
  "missing_oauth_application": false,
  "db_replication_lag_seconds": 0,
  "replication_slots_max_retained_wal_bytes": null,
  "repositories_checked_count": null,
  "repositories_checked_failed_count": null,
  "last_event_id": 357,
  "last_event_timestamp": 1683127088,
  "cursor_last_event_id": 357,
  "cursor_last_event_timestamp": 1683127088,
  "last_successful_status_check_timestamp": 1683127146,
  "version": "16.0.0-pre",
  "revision": "129eb954664",
  "selective_sync_type": "",
  "namespaces": [],
  "updated_at": "2023-05-03T15:19:06.174Z",
  "storage_shards_match": true,
  "_links": {
    "self": "https://primary.example.com/api/v4/geo_sites/2/status",
    "site": "https://primary.example.com/api/v4/geo_sites/2"
  }
}
```

NOTE:
The `health_status` parameter can only be in an "Healthy" or "Unhealthy" state, while the `health` parameter can be empty, "Healthy", or contain the actual error message.
