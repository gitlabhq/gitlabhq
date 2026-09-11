---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Namespaces API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Visibility of billing-related fields changed in GitLab 18.3 [with a feature flag](../administration/feature_flags/_index.md) named `restrict_namespace_api_billing_fields`. Disabled by default.
- Visibility of billing-related fields [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/565598) in GitLab 18.9. Feature flag `restrict_namespace_api_billing_fields` removed.

{{< /history >}}

Use this API to interact with namespaces, a special resource category used to organize users and groups. For more information, see [namespaces](../user/namespace/_index.md).

This API uses [Pagination](rest/_index.md#pagination) to filter results.

## List all namespaces

{{< history >}}

- `ci_minutes_usage` [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/12379) in GitLab 19.4.

{{< /history >}}

Lists all namespaces available to the current user. If the user is an
administrator, this endpoint returns all namespaces in the instance.

```plaintext
GET /namespaces
```

| Attribute          | Type    | Required | Description                                                                             |
|--------------------|---------|----------|-----------------------------------------------------------------------------------------|
| `search`           | string  | no       | Returns only namespaces that contain the specified value in their name or path.         |
| `owned_only`       | boolean | no       | If `true`, only returns namespaces by the current user.                                 |
| `top_level_only`   | boolean | no       | If `true`, only returns top-level namespaces.                                           |
| `full_path_search` | boolean | no       | If `true`, the `search` parameter is matched against the full path of the namespaces. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute | Type | Description |
| --------- | ---- | ----------- |
| `id` | integer | ID of the namespace. | 
| `name` | string | Name of the namespace. | 
| `path` | string | Path segment of the namespace. | 
| `kind` | string | Namespace type: `user` or `group`. | 
| `full_path` | string | Full path of the namespace, including parent paths for subgroups. | 
| `parent_id` | integer | ID of the parent namespace. `null` for top-level namespaces. | 
| `avatar_url` | string | URL of the namespace avatar. `null` if not set. | 
| `web_url` | string | URL of the namespace on GitLab. | 
| `billable_members_count` | integer | Number of billable members in the namespace. | 
| `plan` | string | Subscription plan of the namespace (for example, `free`, `ultimate`). | 
| `end_date` | date | End date of the current subscription. `null` if not applicable. | 
| `trial_ends_on` | date | Date the trial ends. `null` if not on a trial. | 
| `trial` | boolean | Whether the namespace is on a trial plan. | 
| `root_repository_size` | integer | Total size of all repositories in the namespace, in bytes. | 
| `projects_count` | integer | Number of projects in the namespace. | 
| `members_count_with_descendants` | integer | Total number of members including those in subgroups. Only returned for group namespaces. | 
| `max_seats_used` | integer | Maximum number of seats used during the current subscription period. Only returned for Group owners or on GitLab.com. | 
| `max_seats_used_changed_at` | datetime | Timestamp of when `max_seats_used` last changed. Only returned for Group owners or on GitLab.com. | 
| `seats_in_use` | integer | Number of seats currently in use. Only returned for Group owners or on GitLab.com. | 
| `ci_minutes_usage` | object | Compute minutes usage breakdown. On GitLab.com, reflects the [compute minutes quota system](../ci/pipelines/compute_minutes.md) applied to all namespaces. On GitLab Self-Managed and GitLab Dedicated, returned only when [compute quotas are configured on a namespace](../administration/cicd/compute_minutes.md#set-the-compute-quota-for-a-group). Only returned for top-level groups when the user has the Owner role or is an administrator. | 
| `ci_minutes_usage.total_minutes_used` | integer | Total compute minutes used in the current billing period. | 
| `ci_minutes_usage.monthly_minutes_used` | integer | Compute minutes used from the monthly quota. | 
| `ci_minutes_usage.purchased_minutes_used` | integer | Compute minutes used from additional purchased allocations. | 
| `shared_runners_minutes_limit` | integer | Monthly compute minutes quota allocated to the namespace. On GitLab.com only, for instance administrators. | 
| `extra_shared_runners_minutes_limit` | integer | Additional compute minutes added on top of the monthly quota. Reflects purchased minute packs. On GitLab.com only, for instance administrators. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/namespaces"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "user1",
    "path": "user1",
    "kind": "user",
    "full_path": "user1",
    "parent_id": null,
    "avatar_url": "https://secure.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/user1",
    "billable_members_count": 1,
    "plan": "ultimate",
    "end_date": null,
    "trial_ends_on": null,
    "trial": false,
    "root_repository_size": 100,
    "projects_count": 3
  },
  {
    "id": 2,
    "name": "group1",
    "path": "group1",
    "kind": "group",
    "full_path": "group1",
    "parent_id": null,
    "avatar_url": null,
    "web_url": "https://gitlab.example.com/groups/group1",
    "members_count_with_descendants": 2,
    "billable_members_count": 2,
    "plan": "ultimate",
    "end_date": null,
    "trial_ends_on": null,
    "trial": false,
    "root_repository_size": 100,
    "projects_count": 3
  },
  {
    "id": 3,
    "name": "bar",
    "path": "bar",
    "kind": "group",
    "full_path": "foo/bar",
    "parent_id": 9,
    "avatar_url": null,
    "web_url": "https://gitlab.example.com/groups/foo/bar",
    "members_count_with_descendants": 5,
    "billable_members_count": 5,
    "end_date": null,
    "trial_ends_on": null,
    "trial": false,
    "root_repository_size": 100,
    "projects_count": 3
  }
]
```

Additional attributes might be returned for Group owners or on GitLab.com:

```json
[
  {
    ...
    "max_seats_used": 3,
    "max_seats_used_changed_at":"2025-05-15T12:00:02.000Z",
    "seats_in_use": 2,
    "projects_count": 1,
    "root_repository_size":0,
    "members_count_with_descendants":26,
    "plan": "free",
    ...
  }
]
```

## Retrieve namespace details

{{< history >}}

- `ci_minutes_usage` [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/12379) in GitLab 19.4.

{{< /history >}}

Retrieves details for a specified namespace.

```plaintext
GET /namespaces/:id
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer or string | yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the namespace. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute | Type | Description |
| --------- | ---- | ----------- |
| `id` | integer | ID of the namespace. | 
| `name` | string | Name of the namespace. | 
| `path` | string | Path segment of the namespace. | 
| `kind` | string | Namespace type: `user` or `group`. | 
| `full_path` | string | Full path of the namespace, including parent paths for subgroups. | 
| `parent_id` | integer | ID of the parent namespace. `null` for top-level namespaces. | 
| `avatar_url` | string | URL of the namespace avatar. `null` if not set. | 
| `web_url` | string | URL of the namespace on GitLab. | 
| `billable_members_count` | integer | Number of billable members in the namespace. | 
| `plan` | string | Subscription plan of the namespace (for example, `free`, `ultimate`). | 
| `end_date` | date | End date of the current subscription. `null` if not applicable. | 
| `trial_ends_on` | date | Date the trial ends. `null` if not on a trial. | 
| `trial` | boolean | Whether the namespace is on a trial plan. | 
| `root_repository_size` | integer | Total size of all repositories in the namespace, in bytes. | 
| `projects_count` | integer | Number of projects in the namespace. | 
| `members_count_with_descendants` | integer | Total number of members including those in subgroups. Only returned for group namespaces. | 
| `max_seats_used` | integer | Maximum number of seats used during the current subscription period. Only returned for Group owners or on GitLab.com. | 
| `max_seats_used_changed_at` | datetime | Timestamp of when `max_seats_used` last changed. Only returned for Group owners or on GitLab.com. | 
| `seats_in_use` | integer | Number of seats currently in use. Only returned for Group owners or on GitLab.com. | 
| `ci_minutes_usage` | object | Compute minutes usage breakdown. On GitLab.com, reflects the [compute minutes quota system](../ci/pipelines/compute_minutes.md) applied to all namespaces. On GitLab Self-Managed and GitLab Dedicated, returned only when [compute quotas are configured on a namespace](../administration/cicd/compute_minutes.md#set-the-compute-quota-for-a-group). Only returned for top-level groups when the user has the Owner role or is an administrator. | 
| `ci_minutes_usage.total_minutes_used` | integer | Total compute minutes used in the current billing period. | 
| `ci_minutes_usage.monthly_minutes_used` | integer | Compute minutes used from the monthly quota. | 
| `ci_minutes_usage.purchased_minutes_used` | integer | Compute minutes used from additional purchased allocations. | 
| `shared_runners_minutes_limit` | integer | Monthly compute minutes quota allocated to the namespace. On GitLab.com only, for instance administrators. | 
| `extra_shared_runners_minutes_limit` | integer | Additional compute minutes added on top of the monthly quota. Reflects purchased minute packs. On GitLab.com only, for instance administrators. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/namespaces/2"
```

Example response:

```json
{
  "id": 2,
  "name": "group1",
  "path": "group1",
  "kind": "group",
  "full_path": "group1",
  "parent_id": null,
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/group1",
  "members_count_with_descendants": 2,
  "billable_members_count": 2,
  "max_seats_used": 0,
  "seats_in_use": 0,
  "plan": "default",
  "end_date": null,
  "trial_ends_on": null,
  "trial": false,
  "root_repository_size": 100,
  "projects_count": 3,
  "ci_minutes_usage": {
    "total_minutes_used": 450,
    "monthly_minutes_used": 400,
    "purchased_minutes_used": 50
  }
}
```

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/namespaces/group1"
```

Example response:

```json
{
  "id": 2,
  "name": "group1",
  "path": "group1",
  "kind": "group",
  "full_path": "group1",
  "parent_id": null,
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/group1",
  "members_count_with_descendants": 2,
  "billable_members_count": 2,
  "max_seats_used": 0,
  "seats_in_use": 0,
  "plan": "default",
  "end_date": null,
  "trial_ends_on": null,
  "trial": false,
  "root_repository_size": 100,
  "ci_minutes_usage": {
    "total_minutes_used": 450,
    "monthly_minutes_used": 400,
    "purchased_minutes_used": 50
  }
}
```

## Verify namespace availability

Verifies if a specified namespace exists. If the namespace exists, the endpoint suggests an alternate name.

```plaintext
GET /namespaces/:namespace/exists
```

| Attribute   | Type    | Required | Description |
| ----------- | ------- | -------- | ----------- |
| `namespace` | string  | yes      | Path of the namespace. |
| `parent_id` | integer | no       | ID of the parent namespace. If unspecified, only returns top-level namespaces. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/namespaces/my-group/exists?parent_id=1"
```

Example response:

```json
{
    "exists": true,
    "suggests": [
        "my-group1"
    ]
}
```
