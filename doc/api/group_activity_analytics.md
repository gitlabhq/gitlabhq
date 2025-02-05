---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group Activity Analytics API
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

## Get count of recently created issues for group

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

## Get count of recently created merge requests for group

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

## Get count of members recently added to group

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
