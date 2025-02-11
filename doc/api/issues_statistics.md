---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Issues statistics API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Every API call to the [issues](../user/project/issues/_index.md) statistics API must be authenticated.

If a user is not a member of a project and the project is private, a `GET`
request on that project results in a `404` status code.

## Get issues statistics

Gets issues count statistics on all issues the authenticated user has access to. By default it
returns only issues created by the current user. To get all issues,
use parameter `scope=all`.

```plaintext
GET /issues_statistics
GET /issues_statistics?labels=foo
GET /issues_statistics?labels=foo,bar
GET /issues_statistics?labels=foo,bar&state=opened
GET /issues_statistics?milestone=1.0.0
GET /issues_statistics?milestone=1.0.0&state=opened
GET /issues_statistics?iids[]=42&iids[]=43
GET /issues_statistics?author_id=5
GET /issues_statistics?assignee_id=5
GET /issues_statistics?my_reaction_emoji=star
GET /issues_statistics?search=foo&in=title
GET /issues_statistics?confidential=true
```

| Attribute           | Type             | Required   | Description                                                                                                                                         |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `labels`            | string           | no         | Comma-separated list of label names, issues must have all labels to be returned. `None` lists all issues with no labels. `Any` lists all issues with at least one label. |
| `milestone`         | string           | no         | The milestone title. `None` lists all issues with no milestone. `Any` lists all issues that have an assigned milestone.                             |
| `scope`             | string           | no         | Return issues for the given scope: `created_by_me`, `assigned_to_me` or `all`. Defaults to `created_by_me` |
| `author_id`         | integer          | no         | Return issues created by the given user `id`. Mutually exclusive with `author_username`. Combine with `scope=all` or `scope=assigned_to_me`. |
| `author_username`   | string           | no         | Return issues created by the given `username`. Similar to `author_id` and mutually exclusive with `author_id`. |
| `assignee_id`       | integer          | no         | Return issues assigned to the given user `id`. Mutually exclusive with `assignee_username`. `None` returns unassigned issues. `Any` returns issues with an assignee. |
| `assignee_username` | string array     | no         | Return issues assigned to the given `username`. Similar to `assignee_id` and mutually exclusive with `assignee_id`. In GitLab CE `assignee_username` array should only contain a single value or an invalid parameter error is returned otherwise. |
| `epic_id`           | integer      | no         | Return issues associated with the given epic ID. `None` returns issues that are not associated with an epic. `Any` returns issues that are associated with an epic. Premium and Ultimate only. |
| `my_reaction_emoji` | string           | no         | Return issues reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction. |
| `iids[]`            | integer array    | no         | Return only the issues having the given `iid`                                                                                                       |
| `search`            | string           | no         | Search issues against their `title` and `description`                                                                                               |
| `in`                | string           | no         | Modify the scope of the `search` attribute. `title`, `description`, or a string joining them with comma. Default is `title,description`             |
| `created_after`     | datetime         | no         | Return issues created on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `created_before`    | datetime         | no         | Return issues created on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `updated_after`     | datetime         | no         | Return issues updated on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `updated_before`    | datetime         | no         | Return issues updated on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `confidential`      | boolean          | no         | Filter confidential or public issues.                                                                                                               |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/issues_statistics"
```

Example response:

```json
{
  "statistics": {
    "counts": {
      "all": 20,
      "closed": 5,
      "opened": 15
    }
  }
}
```

## Get group issues statistics

Gets issues count statistics for given group.

```plaintext
GET /groups/:id/issues_statistics
GET /groups/:id/issues_statistics?labels=foo
GET /groups/:id/issues_statistics?labels=foo,bar
GET /groups/:id/issues_statistics?labels=foo,bar&state=opened
GET /groups/:id/issues_statistics?milestone=1.0.0
GET /groups/:id/issues_statistics?milestone=1.0.0&state=opened
GET /groups/:id/issues_statistics?iids[]=42&iids[]=43
GET /groups/:id/issues_statistics?search=issue+title+or+description
GET /groups/:id/issues_statistics?author_id=5
GET /groups/:id/issues_statistics?assignee_id=5
GET /groups/:id/issues_statistics?my_reaction_emoji=star
GET /groups/:id/issues_statistics?confidential=true
```

| Attribute           | Type             | Required   | Description                                                                                                                   |
| ------------------- | ---------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths)                 |
| `labels`            | string           | no         | Comma-separated list of label names, issues must have all labels to be returned. `None` lists all issues with no labels. `Any` lists all issues with at least one label. |
| `iids[]`            | integer array    | no         | Return only the issues having the given `iid`                                                                                 |
| `milestone`         | string           | no         | The milestone title. `None` lists all issues with no milestone. `Any` lists all issues that have an assigned milestone.       |
| `scope`             | string           | no         | Return issues for the given scope: `created_by_me`, `assigned_to_me` or `all`. |
| `author_id`         | integer          | no         | Return issues created by the given user `id`. Mutually exclusive with `author_username`. Combine with `scope=all` or `scope=assigned_to_me`. |
| `author_username`   | string           | no         | Return issues created by the given `username`. Similar to `author_id` and mutually exclusive with `author_id`. |
| `assignee_id`       | integer          | no         | Return issues assigned to the given user `id`. Mutually exclusive with `assignee_username`. `None` returns unassigned issues. `Any` returns issues with an assignee. |
| `assignee_username` | string array     | no         | Return issues assigned to the given `username`. Similar to `assignee_id` and mutually exclusive with `assignee_id`. In GitLab CE `assignee_username` array should only contain a single value or an invalid parameter error is returned otherwise. |
| `my_reaction_emoji` | string           | no         | Return issues reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction. |
| `search`            | string           | no         | Search group issues against their `title` and `description`                                                                   |
| `created_after`     | datetime         | no         | Return issues created on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `created_before`    | datetime         | no         | Return issues created on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `updated_after`     | datetime         | no         | Return issues updated on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `updated_before`    | datetime         | no         | Return issues updated on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `confidential`      | boolean          | no         | Filter confidential or public issues.                                                                                         |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/4/issues_statistics"
```

Example response:

```json
{
  "statistics": {
    "counts": {
      "all": 20,
      "closed": 5,
      "opened": 15
    }
  }
}
```

## Get project issues statistics

Gets issues count statistics for given project.

```plaintext
GET /projects/:id/issues_statistics
GET /projects/:id/issues_statistics?labels=foo
GET /projects/:id/issues_statistics?labels=foo,bar
GET /projects/:id/issues_statistics?labels=foo,bar&state=opened
GET /projects/:id/issues_statistics?milestone=1.0.0
GET /projects/:id/issues_statistics?milestone=1.0.0&state=opened
GET /projects/:id/issues_statistics?iids[]=42&iids[]=43
GET /projects/:id/issues_statistics?search=issue+title+or+description
GET /projects/:id/issues_statistics?author_id=5
GET /projects/:id/issues_statistics?assignee_id=5
GET /projects/:id/issues_statistics?my_reaction_emoji=star
GET /projects/:id/issues_statistics?confidential=true
```

| Attribute           | Type             | Required   | Description                                                                                                                   |
| ------------------- | ---------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths)               |
| `iids[]`            | integer array    | no         | Return only the milestone having the given `iid`                                                                              |
| `labels`            | string           | no         | Comma-separated list of label names, issues must have all labels to be returned. `None` lists all issues with no labels. `Any` lists all issues with at least one label. |
| `milestone`         | string           | no         | The milestone title. `None` lists all issues with no milestone. `Any` lists all issues that have an assigned milestone.       |
| `scope`             | string           | no         | Return issues for the given scope: `created_by_me`, `assigned_to_me` or `all`. |
| `author_id`         | integer          | no         | Return issues created by the given user `id`. Mutually exclusive with `author_username`. Combine with `scope=all` or `scope=assigned_to_me`. |
| `author_username`   | string           | no         | Return issues created by the given `username`. Similar to `author_id` and mutually exclusive with `author_id`. |
| `assignee_id`       | integer          | no         | Return issues assigned to the given user `id`. Mutually exclusive with `assignee_username`. `None` returns unassigned issues. `Any` returns issues with an assignee. |
| `assignee_username` | string array     | no         | Return issues assigned to the given `username`. Similar to `assignee_id` and mutually exclusive with `assignee_id`. In GitLab CE `assignee_username` array should only contain a single value or an invalid parameter error is returned otherwise. |
| `my_reaction_emoji` | string           | no         | Return issues reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction. |
| `search`            | string           | no         | Search project issues against their `title` and `description`                                                                 |
| `created_after`     | datetime         | no         | Return issues created on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `created_before`    | datetime         | no         | Return issues created on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `updated_after`     | datetime         | no         | Return issues updated on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `updated_before`    | datetime         | no         | Return issues updated on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `confidential`      | boolean          | no         | Filter confidential or public issues.                                                                                         |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/4/issues_statistics"
```

Example response:

```json
{
  "statistics": {
    "counts": {
      "all": 20,
      "closed": 5,
      "opened": 15
    }
  }
}
```
