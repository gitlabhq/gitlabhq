---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Virtual registries cleanup policies API
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/572839) in GitLab 18.6 [with a flag](../administration/feature_flags/_index.md) named `maven_virtual_registry`. Enabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of these endpoints is controlled by a feature flag.
For more information, see the history.
Review the documentation carefully before you use them.

{{< /alert >}}

Use this API to:

- Create and manage virtual registries cleanup policies.
- Configure cleanup schedules and retention settings.
- Automatically clean up unused cache entries.

## Manage cleanup policies

Use the following endpoints to create and manage virtual registries cleanup policies. Each group can have only one cleanup policy.

### Get the cleanup policy for a group

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/572839) in GitLab 18.6 [with a flag](../administration/feature_flags/_index.md) named `maven_virtual_registry`. Enabled by default.

{{< /history >}}

Gets the cleanup policy for a group. Each group can have only one cleanup policy.

```plaintext
GET /groups/:id/-/virtual_registries/cleanup/policy
```

Supported attributes:

| Attribute | Type | Required | Description |
|:----------|:-----|:---------|:------------|
| `id` | string or integer | Yes | The group ID or full-group path. Must be a top-level group. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/cleanup/policy"
```

Example response:

```json
{
  "group_id": 5,
  "next_run_at": "2024-06-06T12:28:27.855Z",
  "last_run_at": "2024-05-30T12:28:27.855Z",
  "last_run_deleted_size": 1048576,
  "last_run_deleted_entries_count": 25,
  "keep_n_days_after_download": 30,
  "status": "scheduled",
  "cadence": 7,
  "enabled": true,
  "notify_on_success": false,
  "notify_on_failure": false,
  "failure_message": null,
  "last_run_detailed_metrics": {
    "maven": {
      "deleted_entries_count": 25,
      "deleted_size": 1048576
    }
  },
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### Create a cleanup policy

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/572839) in GitLab 18.6 [with a flag](../administration/feature_flags/_index.md) named `maven_virtual_registry`. Enabled by default.

{{< /history >}}

Creates a cleanup policy for a group. Each group can have only one cleanup policy.

```plaintext
POST /groups/:id/-/virtual_registries/cleanup/policy
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | string or integer | Yes | The group ID or full-group path. Must be a top-level group. |
| `cadence` | integer | No | How often the cleanup policy should run. Must be one of: `1` (daily), `7` (weekly), `14` (bi-weekly), `30` (monthly), `90` (quarterly). |
| `enabled` | boolean | No | Enable or disable the cleanup policy. |
| `keep_n_days_after_download` | integer | No | Number of days after which unused cache entries should be cleaned up. Must be between 1 and 365. |
| `notify_on_success` | boolean | No | Notify group owners on successful cleanup runs. |
| `notify_on_failure` | boolean | No | Notify group owners on failed cleanup runs. |

Example request:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --data '{"enabled": true, "keep_n_days_after_download": 30, "cadence": 7}' \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/cleanup/policy"
```

Example response:

```json
{
  "group_id": 5,
  "next_run_at": "2024-06-06T12:28:27.855Z",
  "last_run_at": null,
  "last_run_deleted_size": 0,
  "last_run_deleted_entries_count": 0,
  "keep_n_days_after_download": 30,
  "status": "scheduled",
  "cadence": 7,
  "enabled": true,
  "notify_on_success": false,
  "notify_on_failure": false,
  "failure_message": null,
  "last_run_detailed_metrics": {},
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### Update a cleanup policy

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/572839) in GitLab 18.6 [with a flag](../administration/feature_flags/_index.md) named `maven_virtual_registry`. Enabled by default.

{{< /history >}}

Updates the cleanup policy for a group.

```plaintext
PATCH /groups/:id/-/virtual_registries/cleanup/policy
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | string or integer | Yes | The group ID or full-group path. Must be a top-level group. |
| `cadence` | integer | No | How often the cleanup policy should run. Must be one of: `1` (daily), `7` (weekly), `14` (bi-weekly), `30` (monthly), `90` (quarterly). |
| `enabled` | boolean | No | Boolean to enable/disable the policy. |
| `keep_n_days_after_download` | integer | No | Number of days after which unused cache entries should be cleaned up. Must be between 1 and 365. |
| `notify_on_success` | boolean | No | Notify group owners on successful cleanup runs. |
| `notify_on_failure` | boolean | No | Notify group owners on failed cleanup runs. |

{{< alert type="note" >}}

You must provide at least one of the optional parameters in your request.

{{< /alert >}}

Example request:

```shell
curl --request PATCH \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"keep_n_days_after_download": 60}' \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/cleanup/policy"
```

Example response:

```json
{
  "group_id": 5,
  "next_run_at": "2024-06-06T12:28:27.855Z",
  "last_run_at": "2024-05-30T12:28:27.855Z",
  "last_run_deleted_size": 1048576,
  "last_run_deleted_entries_count": 25,
  "keep_n_days_after_download": 60,
  "status": "scheduled",
  "cadence": 7,
  "enabled": true,
  "notify_on_success": false,
  "notify_on_failure": false,
  "failure_message": null,
  "last_run_detailed_metrics": {
    "maven": {
      "deleted_entries_count": 25,
      "deleted_size": 1048576
    }
  },
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### Delete a cleanup policy

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/572839) in GitLab 18.6 [with a flag](../administration/feature_flags/_index.md) named `maven_virtual_registry`. Enabled by default.

{{< /history >}}

Deletes the cleanup policy for a group.

```plaintext
DELETE /groups/:id/-/virtual_registries/cleanup/policy
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | string or integer | Yes | The group ID or full-group path. Must be a top-level group. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/cleanup/policy"
```

If successful, returns a [`204 No Content`](rest/troubleshooting.md#status-codes) status code.
