---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Geo Nodes API (deprecated)
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< alert type="warning" >}}

The Geo Nodes API was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/369140) in GitLab 16.0
and is planned for removal in v5 of the API. Use the [Geo Sites API](geo_sites.md) instead.
This change is a breaking change.

{{< /alert >}}

To interact with Geo node endpoints, you must authenticate yourself as an
administrator.

## Create a new Geo node

Creates a new Geo node.

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

| Attribute                   | Type    | Required | Description                                                      |
| ----------------------------| ------- | -------- | -----------------------------------------------------------------|
| `primary`                   | boolean | no       | Specifying whether this node should be primary. Defaults to false. |
| `enabled`                   | boolean | no       | Flag indicating if the Geo node is enabled. Defaults to true.    |
| `name`                      | string  | yes      | The unique identifier for the Geo node. Must match `geo_node_name` if it is set in `gitlab.rb`, otherwise it must match `external_url` |
| `url`                       | string  | yes      | The user-facing URL for the Geo node. |
| `internal_url`              | string  | no       | The URL defined on the primary node that secondary nodes should use to contact it. Returns `url` if not set. |
| `files_max_capacity`        | integer | no       | Control the maximum concurrency of LFS/attachment backfill for this secondary node. Defaults to 10. |
| `repos_max_capacity`        | integer | no       | Control the maximum concurrency of repository backfill for this secondary node. Defaults to 25. |
| `verification_max_capacity` | integer | no       | Control the maximum concurrency of repository verification for this node. Defaults to 100. |
| `container_repositories_max_capacity` | integer  | no | Control the maximum concurrency of container repository sync for this node. Defaults to 10. |
| `sync_object_storage`       | boolean | no       | Flag indicating if the secondary Geo node should replicate blobs in Object Storage. Defaults to false. |
| `selective_sync_type`       | string  | no       | Limit syncing to only specific groups or shards. Valid values: `"namespaces"`, `"shards"`, or `null`. |
| `selective_sync_shards`     | array   | no       | The repository storage for the projects synced if `selective_sync_type` == `shards`. |
| `selective_sync_namespace_ids` | array | no      | The IDs of groups that should be synced, if `selective_sync_type` == `namespaces`. |
| `minimum_reverification_interval` | integer | no | The interval (in days) in which the repository verification is valid. Once expired, it is reverified. This has no effect when set on a secondary node. |

Example response:

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

## Retrieve configuration about all Geo nodes

```plaintext
GET /geo_nodes
```

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/geo_nodes"
```

Example response:

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

## Retrieve configuration about a specific Geo node

```plaintext
GET /geo_nodes/:id
```

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/geo_nodes/1"
```

Example response:

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

## Edit a Geo node

Updates settings of an existing Geo node.

```plaintext
PUT /geo_nodes/:id
```

| Attribute                   | Type    | Required | Description                                                               |
|-----------------------------|---------|---------|---------------------------------------------------------------------------|
| `id`                        | integer | yes     | The ID of the Geo node.                                                   |
| `enabled`                   | boolean | no      | Flag indicating if the Geo node is enabled.                               |
| `name`                      | string  | no      | The unique identifier for the Geo node. Must match `geo_node_name` if it is set in `gitlab.rb`, otherwise it must match `external_url`. |
| `url`                       | string  | no      | The user-facing URL of the Geo node. |
| `internal_url`              | string  | no      | The URL defined on the primary node that secondary nodes should use to contact it. Returns `url` if not set.|
| `files_max_capacity`        | integer | no      | Control the maximum concurrency of LFS/attachment backfill for this secondary node. |
| `repos_max_capacity`        | integer | no      | Control the maximum concurrency of repository backfill for this secondary node.     |
| `verification_max_capacity` | integer | no      | Control the maximum concurrency of verification for this node. |
| `container_repositories_max_capacity` | integer | no      | Control the maximum concurrency of container repository sync for this node. |
| `sync_object_storage`       | boolean | no      | Flag indicating if the secondary Geo node should replicate blobs in Object Storage. |
| `selective_sync_type`       | string  | no      | Limit syncing to only specific groups or shards. Valid values: `"namespaces"`, `"shards"`, or `null`. |
| `selective_sync_shards`     | array   | no      | The repository storage for the projects synced if `selective_sync_type` == `shards`. |
| `selective_sync_namespace_ids` | array | no      | The IDs of groups that should be synced, if `selective_sync_type` == `namespaces`. |
| `minimum_reverification_interval` | integer | no      | The interval (in days) in which the repository verification is valid. Once expired, it is reverified. This has no effect when set on a secondary node. |

Example response:

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

## Delete a Geo node

Removes the Geo node.

```plaintext
DELETE /geo_nodes/:id
```

| Attribute | Type    | Required | Description             |
|-----------|---------|----------|-------------------------|
| `id`      | integer | yes      | The ID of the Geo node. |

## Repair a Geo node

To repair the OAuth authentication of a Geo node.

_This can only be run against a primary Geo node._

```plaintext
POST /geo_nodes/:id/repair
```

Example response:

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

## Retrieve status about all Geo nodes

```plaintext
GET /geo_nodes/status
```

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/geo_nodes/status"
```

Example response:

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

## Retrieve status about a specific Geo node

```plaintext
GET /geo_nodes/:id/status
```

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/geo_nodes/2/status"
```

Example response:

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

The `health_status` parameter can only be in a "Healthy" or "Unhealthy" state, while the `health` parameter can be empty, "Healthy", or contain the actual error message.

{{< /alert >}}
