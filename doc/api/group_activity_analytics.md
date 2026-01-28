---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group activity analytics API
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to retrieve information about group activities. For more information, see [group activity analytics](../user/group/manage.md#group-activity-analytics).

## Retrieve count of recently created issues for a group

Retrieves the count of recently created issues for a specified group.

```plaintext
GET /analytics/group_activity/issues_count
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `group_path` | string | yes | Group path |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/analytics/group_activity/issues_count?group_path=gitlab-org"
```

Example response:

```json
{ "issues_count": 10 }
```

## Retrieve count of recently created merge requests for a group

Retrieves the count of recently created merge requests for a specified group.

```plaintext
GET /analytics/group_activity/merge_requests_count
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `group_path` | string | yes | Group path |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/analytics/group_activity/merge_requests_count?group_path=gitlab-org"
```

Example response:

```json
{ "merge_requests_count": 10 }
```

## Retrieve count of members recently added to a group

Retrieves the count of members recently added to a specified group.

```plaintext
GET /analytics/group_activity/new_members_count
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `group_path` | string | yes | Group path |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/analytics/group_activity/new_members_count?group_path=gitlab-org"
```

Example response:

```json
{ "new_members_count": 10 }
```
