---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Geo Nodes API **(PREMIUM SELF)**

To interact with Geo node endpoints, you need to authenticate yourself as an
administrator.

## Create a new Geo node

Creates a new Geo node.

```plaintext
POST /geo_nodes
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/geo_nodes" \
     --request POST \
     -d "name=himynameissomething" \
     -d "url=https://another-node.example.com/"
```

| Attribute                   | Type    | Required | Description                                                      |
| ----------------------------| ------- | -------- | -----------------------------------------------------------------|
| `primary`                   | boolean | no       | Specifying whether this node will be primary. Defaults to false. |
| `enabled`                   | boolean | no       | Flag indicating if the Geo node is enabled. Defaults to true.    |
| `name`                      | string  | yes      | The unique identifier for the Geo node. Must match `geo_node_name` if it is set in `gitlab.rb`, otherwise it must match `external_url` |
| `url`                       | string  | yes      | The user-facing URL for the Geo node. |
| `internal_url`              | string  | no       | The URL defined on the primary node that secondary nodes should use to contact it. Returns `url` if not set. |
| `files_max_capacity`        | integer | no       | Control the maximum concurrency of LFS/attachment backfill for this secondary node. Defaults to 10. |
| `repos_max_capacity`        | integer | no       | Control the maximum concurrency of repository backfill for this secondary node. Defaults to 25. |
| `verification_max_capacity` | integer | no       | Control the maximum concurrency of repository verification for this node. Defaults to 100. |
| `container_repositories_max_capacity` | integer  | no | Control the maximum concurrency of container repository sync for this node. Defaults to 10. |
| `sync_object_storage`       | boolean | no       | Flag indicating if the secondary Geo node will replicate blobs in Object Storage. Defaults to false. |
| `selective_sync_type`       | string  | no       | Limit syncing to only specific groups or shards. Valid values: `"namespaces"`, `"shards"`, or `null`. |
| `selective_sync_shards`     | array   | no       | The repository storage for the projects synced if `selective_sync_type` == `shards`. |
| `selective_sync_namespace_ids` | array | no      | The IDs of groups that should be synced, if `selective_sync_type` == `namespaces`. |
| `minimum_reverification_interval` | integer | no | The interval (in days) in which the repository verification is valid. Once expired, it will be reverified. This has no effect when set on a secondary node. |

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
  "web_edit_url": "https://primary.example.com/admin/geo/nodes/3/edit",
  "web_geo_projects_url": "http://secondary.example.com/admin/geo/projects",
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
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/geo_nodes"
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
    "web_edit_url": "https://primary.example.com/admin/geo/nodes/1/edit",
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
    "web_edit_url": "https://primary.example.com/admin/geo/nodes/2/edit",
    "web_geo_projects_url": "https://secondary.example.com/admin/geo/projects",
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
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/geo_nodes/1"
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
  "web_edit_url": "https://primary.example.com/admin/geo/nodes/1/edit",
  "_links": {
    "self": "https://primary.example.com/api/v4/geo_nodes/1",
    "status":"https://primary.example.com/api/v4/geo_nodes/1/status",
    "repair":"https://primary.example.com/api/v4/geo_nodes/1/repair"
  }
}
```

## Edit a Geo node

Updates settings of an existing Geo node.

_This can only be run against a primary Geo node._

```plaintext
PUT /geo_nodes/:id
```

| Attribute                   | Type    | Required  | Description                                                               |
|-----------------------------|---------|-----------|---------------------------------------------------------------------------|
| `id`                        | integer | yes       | The ID of the Geo node.                                                   |
| `enabled`                   | boolean | no        | Flag indicating if the Geo node is enabled.                               |
| `name`                      | string  | yes       | The unique identifier for the Geo node. Must match `geo_node_name` if it is set in `gitlab.rb`, otherwise it must match `external_url`. |
| `url`                       | string  | yes       | The user-facing URL of the Geo node. |
| `internal_url`              | string  | no        | The URL defined on the primary node that secondary nodes should use to contact it. Returns `url` if not set.|
| `files_max_capacity`        | integer | no        | Control the maximum concurrency of LFS/attachment backfill for this secondary node. |
| `repos_max_capacity`        | integer | no        | Control the maximum concurrency of repository backfill for this secondary node.     |
| `verification_max_capacity` | integer | no        | Control the maximum concurrency of verification for this node. |
| `container_repositories_max_capacity` | integer | no | Control the maximum concurrency of container repository sync for this node. |
| `sync_object_storage`       | boolean | no        | Flag indicating if the secondary Geo node will replicate blobs in Object Storage. |
| `selective_sync_type`       | string  | no        | Limit syncing to only specific groups or shards. Valid values: `"namespaces"`, `"shards"`, or `null`. |
| `selective_sync_shards`     | array   | no        | The repository storage for the projects synced if `selective_sync_type` == `shards`. |
| `selective_sync_namespace_ids` | array | no       | The IDs of groups that should be synced, if `selective_sync_type` == `namespaces`. |
| `minimum_reverification_interval` | integer | no | The interval (in days) in which the repository verification is valid. Once expired, it will be reverified. This has no effect when set on a secondary node. |

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
  "web_edit_url": "https://primary.example.com/admin/geo/nodes/2/edit",
  "web_geo_projects_url": "https://secondary.example.com/admin/geo/projects",
  "_links": {
    "self":"https://primary.example.com/api/v4/geo_nodes/2",
    "status":"https://primary.example.com/api/v4/geo_nodes/2/status",
    "repair":"https://primary.example.com/api/v4/geo_nodes/2/repair"
  }
}
```

## Delete a Geo node

Removes the Geo node.

NOTE:
Only a Geo primary node will accept this request.

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
  "web_edit_url": "https://primary.example.com/admin/geo/nodes/1/edit",
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
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/geo_nodes/status"
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
    "attachments_count": 1,
    "attachments_synced_count": null,
    "attachments_failed_count": null,
    "attachments_synced_missing_on_primary_count": 0,
    "attachments_synced_in_percentage": "0.00%",
    "db_replication_lag_seconds": null,
    "lfs_objects_count": 0,
    "lfs_objects_synced_count": null,
    "lfs_objects_failed_count": null,
    "lfs_objects_synced_missing_on_primary_count": 0,
    "lfs_objects_synced_in_percentage": "0.00%",
    "job_artifacts_count": 2,
    "job_artifacts_synced_count": null,
    "job_artifacts_failed_count": null,
    "job_artifacts_synced_missing_on_primary_count": 0,
    "job_artifacts_synced_in_percentage": "0.00%",
    "container_repositories_count": 3,
    "container_repositories_synced_count": null,
    "container_repositories_failed_count": null,
    "container_repositories_synced_in_percentage": "0.00%",
    "design_repositories_count": 3,
    "design_repositories_synced_count": null,
    "design_repositories_failed_count": null,
    "design_repositories_synced_in_percentage": "0.00%",
    "projects_count": 41,
    "repositories_count": 41,
    "repositories_failed_count": null,
    "repositories_synced_count": null,
    "repositories_synced_in_percentage": "0.00%",
    "wikis_count": 41,
    "wikis_failed_count": null,
    "wikis_synced_count": null,
    "wikis_synced_in_percentage": "0.00%",
    "replication_slots_count": 1,
    "replication_slots_used_count": 1,
    "replication_slots_used_in_percentage": "100.00%",
    "replication_slots_max_retained_wal_bytes": 0,
    "repositories_checked_count": 20,
    "repositories_checked_failed_count": 20,
    "repositories_checked_in_percentage": "100.00%",
    "repositories_checksummed_count": 20,
    "repositories_checksum_failed_count": 5,
    "repositories_checksummed_in_percentage": "48.78%",
    "wikis_checksummed_count": 10,
    "wikis_checksum_failed_count": 3,
    "wikis_checksummed_in_percentage": "24.39%",
    "repositories_verified_count": 20,
    "repositories_verification_failed_count": 5,
    "repositories_verified_in_percentage": "48.78%",
    "repositories_checksum_mismatch_count": 3,
    "wikis_verified_count": 10,
    "wikis_verification_failed_count": 3,
    "wikis_verified_in_percentage": "24.39%",
    "wikis_checksum_mismatch_count": 1,
    "repositories_retrying_verification_count": 1,
    "wikis_retrying_verification_count": 3,
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
  },
  {
    "geo_node_id": 2,
    "healthy": true,
    "health": "Healthy",
    "health_status": "Healthy",
    "missing_oauth_application": false,
    "attachments_count": 1,
    "attachments_synced_count": 1,
    "attachments_failed_count": 0,
    "attachments_synced_missing_on_primary_count": 0,
    "attachments_synced_in_percentage": "100.00%",
    "db_replication_lag_seconds": 0,
    "lfs_objects_count": 0,
    "lfs_objects_synced_count": 0,
    "lfs_objects_failed_count": 0,
    "lfs_objects_synced_missing_on_primary_count": 0,
    "lfs_objects_synced_in_percentage": "0.00%",
    "job_artifacts_count": 2,
    "job_artifacts_synced_count": 1,
    "job_artifacts_failed_count": 1,
    "job_artifacts_synced_missing_on_primary_count": 0,
    "job_artifacts_synced_in_percentage": "50.00%",
    "container_repositories_count": 3,
    "container_repositories_synced_count": null,
    "container_repositories_failed_count": null,
    "container_repositories_synced_in_percentage": "0.00%",
    "design_repositories_count": 3,
    "design_repositories_synced_count": null,
    "design_repositories_failed_count": null,
    "design_repositories_synced_in_percentage": "0.00%",
    "projects_count": 41,
    "repositories_count": 41,
    "repositories_failed_count": 1,
    "repositories_synced_count": 40,
    "repositories_synced_in_percentage": "97.56%",
    "wikis_count": 41,
    "wikis_failed_count": 0,
    "wikis_synced_count": 41,
    "wikis_synced_in_percentage": "100.00%",
    "replication_slots_count": null,
    "replication_slots_used_count": null,
    "replication_slots_used_in_percentage": "0.00%",
    "replication_slots_max_retained_wal_bytes": null,
    "repositories_checksummed_count": 20,
    "repositories_checksum_failed_count": 5,
    "repositories_checksummed_in_percentage": "48.78%",
    "wikis_checksummed_count": 10,
    "wikis_checksum_failed_count": 3,
    "wikis_checksummed_in_percentage": "24.39%",
    "repositories_verified_count": 20,
    "repositories_verification_failed_count": 5,
    "repositories_verified_in_percentage": "48.78%",
    "repositories_checksum_mismatch_count": 3,
    "wikis_verified_count": 10,
    "wikis_verification_failed_count": 3,
    "wikis_verified_in_percentage": "24.39%",
    "wikis_checksum_mismatch_count": 1,
    "repositories_retrying_verification_count": 4,
    "wikis_retrying_verification_count": 2,
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
  }
]
```

## Retrieve status about a specific Geo node

```plaintext
GET /geo_nodes/:id/status
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/geo_nodes/2/status"
```

Example response:

```json
{
  "geo_node_id": 2,
  "healthy": true,
  "health": "Healthy",
  "health_status": "Healthy",
  "missing_oauth_application": false,
  "attachments_count": 1,
  "attachments_synced_count": 1,
  "attachments_failed_count": 0,
  "attachments_synced_missing_on_primary_count": 0,
  "attachments_synced_in_percentage": "100.00%",
  "db_replication_lag_seconds": 0,
  "lfs_objects_count": 0,
  "lfs_objects_synced_count": 0,
  "lfs_objects_failed_count": 0,
  "lfs_objects_synced_missing_on_primary_count": 0,
  "lfs_objects_synced_in_percentage": "0.00%",
  "job_artifacts_count": 2,
  "job_artifacts_synced_count": 1,
  "job_artifacts_failed_count": 1,
  "job_artifacts_synced_missing_on_primary_count": 0,
  "job_artifacts_synced_in_percentage": "50.00%",
  "container_repositories_count": 3,
  "container_repositories_synced_count": null,
  "container_repositories_failed_count": null,
  "container_repositories_synced_in_percentage": "0.00%",
  "design_repositories_count": 3,
  "design_repositories_synced_count": null,
  "design_repositories_failed_count": null,
  "design_repositories_synced_in_percentage": "0.00%",
  "projects_count": 41,
  "repositories_count": 41,
  "repositories_failed_count": 1,
  "repositories_synced_count": 40,
  "repositories_synced_in_percentage": "97.56%",
  "wikis_count": 41,
  "wikis_failed_count": 0,
  "wikis_synced_count": 41,
  "wikis_synced_in_percentage": "100.00%",
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
}
```

NOTE:
The `health_status` parameter can only be in an "Healthy" or "Unhealthy" state, while the `health` parameter can be empty, "Healthy", or contain the actual error message.

## Retrieve project sync or verification failures that occurred on the current node

This only works on a secondary node.

```plaintext
GET /geo_nodes/current/failures
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `type`         | string  | no | Type of failed objects (`repository`/`wiki`) |
| `failure_type` | string | no | Type of failures (`sync`/`checksum_mismatch`/`verification`) |

This endpoint uses [Pagination](index.md#pagination).

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/geo_nodes/current/failures"
```

Example response:

```json
[
  {
    "project_id": 3,
    "last_repository_synced_at": "2017-10-31 14:25:55 UTC",
    "last_repository_successful_sync_at": "2017-10-31 14:26:04 UTC",
    "last_wiki_synced_at": "2017-10-31 14:26:04 UTC",
    "last_wiki_successful_sync_at": "2017-10-31 14:26:11 UTC",
    "repository_retry_count": null,
    "wiki_retry_count": 1,
    "last_repository_sync_failure": null,
    "last_wiki_sync_failure": "Error syncing Wiki repository",
    "last_repository_verification_failure": "",
    "last_wiki_verification_failure": "",
    "repository_verification_checksum_sha": "da39a3ee5e6b4b0d32e5bfef9a601890afd80709",
    "wiki_verification_checksum_sha": "da39a3ee5e6b4b0d3255bfef9ef0189aafd80709",
    "repository_checksum_mismatch": false,
    "wiki_checksum_mismatch": false
  }
]
```
