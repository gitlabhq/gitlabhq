---
stage: Create
group: Code Review
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, api
---

# Merge requests API **(FREE)**

> - `author_id`, `author_username`, and `assignee_id` were [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/13060) in GitLab 9.5.
> - `my_reaction_emoji` was [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/14016) in GitLab 10.0.
> - For the `scope` attribute, `created-by-me` and `assigned-to-me` were [deprecated](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/18935) in favor of `created_by_me` and `assigned_to_me` in GitLab 11.0.
> - `with_labels_details` was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/21413) in GitLab 12.7.
> - `author_username` and `author_username` were [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/13060) in GitLab 12.10.
> - `reference` was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20354) in GitLab 12.10 in favour of `references`.
> - `with_merge_status_recheck` was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/31890) in GitLab 13.0.
> - `reviewer_username` and `reviewer_id` were [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49341) in GitLab 13.8.
> - `reviewer_ids` was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/51186) in GitLab 13.8.
> - `draft` was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63473) as an eventual replacement for `work_in_progress` in GitLab 14.0

Every API call to merge requests must be authenticated.

**Important notes:**

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/29984) in GitLab 12.8, the mergeability (`merge_status`)
of each merge request is checked asynchronously when a request is made to this endpoint. Poll this API endpoint
to get updated status. This affects the `has_conflicts` property as it is dependent on the `merge_status`. It returns
`false` unless `merge_status` is `cannot_be_merged`.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/31890) in GitLab 13.0, listing merge requests may
not proactively update `merge_status` (which also affects the `has_conflicts`), as this can be an expensive operation.
If you need the value of these fields from this endpoint, set the `with_merge_status_recheck` parameter to
`true` in the query.
- `references.relative` is relative to the group or project that the merge request is being requested. When the merge request
is fetched from its project, `relative` format would be the same as `short` format, and when requested across groups or projects, it is expected to be the same as `full` format.
- If `approvals_before_merge` is not provided, it inherits the value from the target project. If provided, the following conditions must hold for it to take effect:

  - The target project's `approvals_before_merge` must be greater than zero. A
    value of zero disables approvals for that project.
  - The provided value of `approvals_before_merge` must be greater than the
    target project's `approvals_before_merge`.

  This API returns `HTTP 201 Created` for a successful response.

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/46190) in GitLab 13.6,
diffs associated with the set of changes have the same size limitations applied as other diffs
returned by the API or viewed via the UI. When these limits impact the results, the `overflow`
field contains a value of `true`. Diff data without these limits applied can be retrieved by
adding the `access_raw_diffs` parameter, accessing diffs not from the database but from Gitaly directly.
This approach is generally slower and more resource-intensive, but isn't subject to size limits
placed on database-backed diffs. [Limits inherent to Gitaly](../development/diffs.md#diff-limits)
still apply.

## List merge requests

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/13060) in GitLab 9.5.

Get all merge requests the authenticated user has access to. By
default it returns only merge requests created by the current user. To
get all merge requests, use parameter `scope=all`.

The `state` parameter can be used to get only merge requests with a
given state (`opened`, `closed`, `locked`, or `merged`) or all of them (`all`). It should be noted that when searching by `locked` it mostly returns no results as it is a short-lived, transitional state.
The pagination parameters `page` and `per_page` can be used to
restrict the list of merge requests.

```plaintext
GET /merge_requests
GET /merge_requests?state=opened
GET /merge_requests?state=all
GET /merge_requests?milestone=release
GET /merge_requests?labels=bug,reproduced
GET /merge_requests?author_id=5
GET /merge_requests?author_username=gitlab-bot
GET /merge_requests?my_reaction_emoji=star
GET /merge_requests?scope=assigned_to_me
GET /merge_requests?search=foo&in=title
```

Parameters:

| Attribute                       | Type           | Required | Description                                                                                                            |
| ------------------------------- | -------------- | -------- | ---------------------------------------------------------------------------------------------------------------------- |
| `state`                         | string         | no       | Return all merge requests or just those that are `opened`, `closed`, `locked`, or `merged`.                             |
| `order_by`                      | string         | no       | Return requests ordered by `created_at` or `updated_at` fields. Default is `created_at`.                                |
| `sort`                          | string         | no       | Return requests sorted in `asc` or `desc` order. Default is `desc`.                                                     |
| `milestone`                     | string         | no       | Return merge requests for a specific milestone. `None` returns merge requests with no milestone. `Any` returns merge requests that have an assigned milestone. |
| `view`                          | string         | no       | If `simple`, returns the `iid`, URL, title, description, and basic state of merge request.                              |
| `labels`                        | string         | no       | Return merge requests matching a comma separated list of labels. `None` lists all merge requests with no labels. `Any` lists all merge requests with at least one label. `No+Label` (Deprecated) lists all merge requests with no labels. Predefined names are case-insensitive. |
| `with_labels_details`           | boolean        | no       | If `true`, response returns more details for each label in labels field: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. Default is `false`. |
| `with_merge_status_recheck`     | boolean        | no       | If `true`, this projection requests (but does not guarantee) that the `merge_status` field be recalculated asynchronously. Default is `false`. |
| `created_after`                 | datetime       | no       | Return merge requests created on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `created_before`                | datetime       | no       | Return merge requests created on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `updated_after`                 | datetime       | no       | Return merge requests updated on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `updated_before`                | datetime       | no       | Return merge requests updated on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `scope`                         | string         | no       | Return merge requests for the given scope: `created_by_me`, `assigned_to_me` or `all`. Defaults to `created_by_me`<br> For versions before 11.0, use the now deprecated `created-by-me` or `assigned-to-me` scopes instead. |
| `author_id`                     | integer        | no       | Returns merge requests created by the given user `id`. Mutually exclusive with `author_username`. Combine with `scope=all` or `scope=assigned_to_me`. |
| `author_username`               | string         | no       | Returns merge requests created by the given `username`. Mutually exclusive with `author_id`.             |
| `assignee_id`                   | integer        | no       | Returns merge requests assigned to the given user `id`. `None` returns unassigned merge requests. `Any` returns merge requests with an assignee. |
| `approver_ids` **(PREMIUM)**    | integer array  | no       | Returns merge requests which have specified all the users with the given `id`s as individual approvers. `None` returns merge requests without approvers. `Any` returns merge requests with an approver. |
| `approved_by_ids` **(PREMIUM)** | integer array  | no       | Returns merge requests which have been approved by all the users with the given `id`s (Max: 5). `None` returns merge requests with no approvals. `Any` returns merge requests with an approval. |
| `reviewer_id`                   | integer        | no       | Returns merge requests which have the user as a [reviewer](../user/project/merge_requests/getting_started.md#reviewer) with the given user `id`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer. Mutually exclusive with `reviewer_username`.  |
| `reviewer_username`             | string         | no       | Returns merge requests which have the user as a [reviewer](../user/project/merge_requests/getting_started.md#reviewer) with the given `username`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer. Mutually exclusive with `reviewer_id`. |
| `my_reaction_emoji`             | string         | no       | Return merge requests reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction. |
| `source_branch`                 | string         | no       | Return merge requests with the given source branch.                                                                     |
| `target_branch`                 | string         | no       | Return merge requests with the given target branch.                                                                     |
| `search`                        | string         | no       | Search merge requests against their `title` and `description`.                                                          |
| `in`                            | string         | no       | Modify the scope of the `search` attribute. `title`, `description`, or a string joining them with comma. Default is `title,description`. |
| `wip`                           | string         | no       | Filter merge requests against their `wip` status. `yes` to return *only* draft merge requests, `no` to return *non-draft* merge requests. |
| `not`                           | Hash           | no       | Return merge requests that do not match the parameters supplied. Accepts: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `reviewer_id`, `reviewer_username`, `my_reaction_emoji`. |
| `environment`                   | string         | no       | Returns merge requests deployed to the given environment. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `deployed_before`               | datetime       | no       | Return merge requests deployed before the given date/time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `deployed_after`                | datetime       | no       | Return merge requests deployed after the given date/time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 3,
    "title": "test1",
    "description": "fixed login page css paddings",
    "state": "merged",
    "merged_by": {
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merged_at": "2018-09-07T11:16:17.520Z",
    "closed_by": null,
    "closed_at": null,
    "created_at": "2017-04-29T08:46:00Z",
    "updated_at": "2017-04-29T08:46:00Z",
    "target_branch": "master",
    "source_branch": "test1",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignee": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignees": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/axel.block"
    }],
    "reviewers": [{
      "id": 2,
      "name": "Sam Bauch",
      "username": "kenyatta_oconnell",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/956c92487c6f6f7616b536927e22c9a0?s=80&d=identicon",
      "web_url": "http://gitlab.example.com//kenyatta_oconnell"
    }],
    "source_project_id": 2,
    "target_project_id": 3,
    "labels": [
      "Community contribution",
      "Manage"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 5,
      "iid": 1,
      "project_id": 3,
      "title": "v2.0",
      "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
      "state": "closed",
      "created_at": "2015-02-02T19:49:26.013Z",
      "updated_at": "2015-02-02T19:49:26.013Z",
      "due_date": "2018-09-22",
      "start_date": "2018-08-08",
      "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
    },
    "merge_when_pipeline_succeeds": true,
    "merge_status": "can_be_merged",
    "sha": "8888888888888888888888888888888888888888",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 1,
    "discussion_locked": null,
    "should_remove_source_branch": true,
    "force_remove_source_branch": false,
    "allow_collaboration": false,
    "allow_maintainer_to_push": false,
    "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
    "references": {
      "short": "!1",
      "relative": "my-group/my-project!1",
      "full": "my-group/my-project!1"
    },
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "squash": false,
    "task_completion_status":{
      "count":0,
      "completed_count":0
    }
  }
]
```

Users on GitLab Premium or higher also see
the `approvals_before_merge` parameter:

```json
[
  {
    "id": 1,
    "title": "test1",
    "approvals_before_merge": null
    ...
  }
]
```

## List project merge requests

Get all merge requests for this project.
The `state` parameter can be used to get only merge requests with a given state (`opened`, `closed`, `locked`, or `merged`) or all of them (`all`).
The pagination parameters `page` and `per_page` can be used to restrict the list of merge requests.

```plaintext
GET /projects/:id/merge_requests
GET /projects/:id/merge_requests?state=opened
GET /projects/:id/merge_requests?state=all
GET /projects/:id/merge_requests?iids[]=42&iids[]=43
GET /projects/:id/merge_requests?milestone=release
GET /projects/:id/merge_requests?labels=bug,reproduced
GET /projects/:id/merge_requests?my_reaction_emoji=star
```

`project_id` represents the ID of the project where the MR resides.
`project_id` always equals `target_project_id`.

In the case of a merge request from the same project,
`source_project_id`, `target_project_id` and `project_id`
are the same. In the case of a merge request from a fork,
`target_project_id` and `project_id` are the same and
`source_project_id` is the fork project's ID.

Parameters:

| Attribute                       | Type           | Required | Description                                                                                                                    |
| ------------------------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `id`                            | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user.                |
| `iids[]`                        | integer array  | no       | Return the request having the given `iid`.                                                                                      |
| `state`                         | string         | no       | Return all merge requests or just those that are `opened`, `closed`, `locked`, or `merged`.                                     |
| `order_by`                      | string         | no       | Return requests ordered by `created_at` or `updated_at` fields. Default is `created_at`.                                        |
| `sort`                          | string         | no       | Return requests sorted in `asc` or `desc` order. Default is `desc`.                                                             |
| `milestone`                     | string         | no       | Return merge requests for a specific milestone. `None` returns merge requests with no milestone. `Any` returns merge requests that have an assigned milestone. |
| `view`                          | string         | no       | If `simple`, returns the `iid`, URL, title, description, and basic state of merge request.                                      |
| `labels`                        | string         | no       | Return merge requests matching a comma separated list of labels. `None` lists all merge requests with no labels. `Any` lists all merge requests with at least one label. `No+Label` (Deprecated) lists all merge requests with no labels. Predefined names are case-insensitive. |
| `with_labels_details`           | boolean        | no       | If `true`, response returns more details for each label in labels field: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. Default is `false`. |
| `with_merge_status_recheck`     | boolean        | no       | If `true`, this projection requests (but does not guarantee) that the `merge_status` field be recalculated asynchronously. Default is `false`. |
| `created_after`                 | datetime       | no       | Return merge requests created on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `created_before`                | datetime       | no       | Return merge requests created on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `updated_after`                 | datetime       | no       | Return merge requests updated on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `updated_before`                | datetime       | no       | Return merge requests updated on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `scope`                         | string         | no       | Return merge requests for the given scope: `created_by_me`, `assigned_to_me`, or `all`. |
| `author_id`                     | integer        | no       | Returns merge requests created by the given user `id`. Mutually exclusive with `author_username`. |
| `author_username`               | string         | no       | Returns merge requests created by the given `username`. Mutually exclusive with `author_id`.|
| `assignee_id`                   | integer        | no       | Returns merge requests assigned to the given user `id`. `None` returns unassigned merge requests. `Any` returns merge requests with an assignee. |
| `approver_ids` **(PREMIUM)**    | integer array  | no       | Returns merge requests which have specified all the users with the given `id`s as individual approvers. `None` returns merge requests without approvers. `Any` returns merge requests with an approver. |
| `approved_by_ids` **(PREMIUM)** | integer array  | no       | Returns merge requests which have been approved by all the users with the given `id`s (Max: 5). `None` returns merge requests with no approvals. `Any` returns merge requests with an approval. |
| `reviewer_id`                   | integer        | no       | Returns merge requests which have the user as a [reviewer](../user/project/merge_requests/getting_started.md#reviewer) with the given user `id`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer. Mutually exclusive with `reviewer_username`.  |
| `reviewer_username`             | string         | no       | Returns merge requests which have the user as a [reviewer](../user/project/merge_requests/getting_started.md#reviewer) with the given `username`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer. Mutually exclusive with `reviewer_id`. |

| `my_reaction_emoji`             | string         | no       | Return merge requests reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction. |
| `source_branch`                 | string         | no       | Return merge requests with the given source branch.                                                                             |
| `target_branch`                 | string         | no       | Return merge requests with the given target branch.                                                                             |
| `search`                        | string         | no       | Search merge requests against their `title` and `description`.                                                                  |
| `wip`                           | string         | no       | Filter merge requests against their `wip` status. `yes` to return *only* draft merge requests, `no` to return *non-draft* merge requests. |
| `not`                           | Hash           | no       | Return merge requests that do not match the parameters supplied. Accepts: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `reviewer_id`, `reviewer_username`, `my_reaction_emoji`. |

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 3,
    "title": "test1",
    "description": "fixed login page css paddings",
    "state": "merged",
    "merged_by": {
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merged_at": "2018-09-07T11:16:17.520Z",
    "closed_by": null,
    "closed_at": null,
    "created_at": "2017-04-29T08:46:00Z",
    "updated_at": "2017-04-29T08:46:00Z",
    "target_branch": "master",
    "source_branch": "test1",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignee": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignees": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/axel.block"
    }],
    "reviewers": [{
      "id": 2,
      "name": "Sam Bauch",
      "username": "kenyatta_oconnell",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/956c92487c6f6f7616b536927e22c9a0?s=80&d=identicon",
      "web_url": "http://gitlab.example.com//kenyatta_oconnell"
    }],
    "source_project_id": 2,
    "target_project_id": 3,
    "labels": [
      "Community contribution",
      "Manage"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 5,
      "iid": 1,
      "project_id": 3,
      "title": "v2.0",
      "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
      "state": "closed",
      "created_at": "2015-02-02T19:49:26.013Z",
      "updated_at": "2015-02-02T19:49:26.013Z",
      "due_date": "2018-09-22",
      "start_date": "2018-08-08",
      "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
    },
    "merge_when_pipeline_succeeds": true,
    "merge_status": "can_be_merged",
    "sha": "8888888888888888888888888888888888888888",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 1,
    "discussion_locked": null,
    "should_remove_source_branch": true,
    "force_remove_source_branch": false,
    "allow_collaboration": false,
    "allow_maintainer_to_push": false,
    "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
    "references": {
      "short": "!1",
      "relative": "!1",
      "full": "my-group/my-project!1"
    },
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "squash": false,
    "task_completion_status":{
      "count":0,
      "completed_count":0
    },
    "has_conflicts": false,
    "blocking_discussions_resolved": true
  }
]
```

The `merge_status` field may hold one of the following values:

| Value                      | Interpretation                                                        |
|----------------------------|-----------------------------------------------------------------------|
| `unchecked`                | We have not checked this yet                                          |
| `checking`                 | We are currently checking if the merge request can be merged          |
| `can_be_merged`            | This merge request can be merged without conflict                     |
| `cannot_be_merged`         | There are merge conflicts between the source and target branches      |
| `cannot_be_merged_recheck` | Currently unchecked. Before the current changes, there were conflicts |

Users on GitLab Premium or higher also see
the `approvals_before_merge` parameter:

```json
[
  {
    "id": 1,
    "title": "test1",
    "approvals_before_merge": null
    ...
  }
]
```

## List group merge requests

Get all merge requests for this group and its subgroups.
The `state` parameter can be used to get only merge requests with a given state (`opened`, `closed`, `locked`, or `merged`) or all of them (`all`).
The pagination parameters `page` and `per_page` can be used to restrict the list of merge requests.

```plaintext
GET /groups/:id/merge_requests
GET /groups/:id/merge_requests?state=opened
GET /groups/:id/merge_requests?state=all
GET /groups/:id/merge_requests?milestone=release
GET /groups/:id/merge_requests?labels=bug,reproduced
GET /groups/:id/merge_requests?my_reaction_emoji=star
```

`group_id` represents the ID of the group which contains the project where the MR resides.

Parameters:

| Attribute                       | Type           | Required | Description                                                                                                                    |
| ------------------------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `id`                            | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user.                  |
| `state`                         | string         | no       | Return all merge requests or just those that are `opened`, `closed`, `locked`, or `merged`.                                     |
| `order_by`                      | string         | no       | Return merge requests ordered by `created_at` or `updated_at` fields. Default is `created_at`.                                  |
| `sort`                          | string         | no       | Return merge requests sorted in `asc` or `desc` order. Default is `desc`.                                                       |
| `milestone`                     | string         | no       | Return merge requests for a specific milestone. `None` returns merge requests with no milestone. `Any` returns merge requests that have an assigned milestone. |
| `view`                          | string         | no       | If `simple`, returns the `iid`, URL, title, description, and basic state of merge request.                                      |
| `labels`                        | string         | no       | Return merge requests matching a comma separated list of labels. `None` lists all merge requests with no labels. `Any` lists all merge requests with at least one label. `No+Label` (Deprecated) lists all merge requests with no labels. Predefined names are case-insensitive. |
| `with_labels_details`           | boolean        | no       | If `true`, response returns more details for each label in labels field: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. Default is `false`. Introduced in [GitLab 12.7](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/21413).|
| `with_merge_status_recheck`     | boolean        | no       | If `true`, this projection requests (but does not guarantee) that the `merge_status` field be recalculated asynchronously. Default is `false`. Introduced in [GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/31890). |
| `created_after`                 | datetime       | no       | Return merge requests created on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `created_before`                | datetime       | no       | Return merge requests created on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `updated_after`                 | datetime       | no       | Return merge requests updated on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `updated_before`                | datetime       | no       | Return merge requests updated on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `scope`                         | string         | no       | Return merge requests for the given scope: `created_by_me`, `assigned_to_me` or `all`.                                     |
| `author_id`                     | integer        | no       | Returns merge requests created by the given user `id`. Mutually exclusive with `author_username`. _([Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/13060) in GitLab 9.5)_. |
| `author_username`               | string         | no       | Returns merge requests created by the given `username`. Mutually exclusive with `author_id`. _([Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/13060) in GitLab 12.10)_. |
| `assignee_id`                   | integer        | no       | Returns merge requests assigned to the given user `id`. `None` returns unassigned merge requests. `Any` returns merge requests with an assignee. _([Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/13060) in GitLab 9.5)_. |
| `approver_ids` **(PREMIUM)**    | integer array  | no       | Returns merge requests which have specified all the users with the given `id`s as individual approvers. `None` returns merge requests without approvers. `Any` returns merge requests with an approver. |
| `approved_by_ids` **(PREMIUM)** | integer array  | no       | Returns merge requests which have been approved by all the users with the given `id`s (Max: 5). `None` returns merge requests with no approvals. `Any` returns merge requests with an approval. |
| `reviewer_id`                   | integer        | no       | Returns merge requests which have the user as a [reviewer](../user/project/merge_requests/getting_started.md#reviewer) with the given user `id`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer. Mutually exclusive with `reviewer_username`.  |
| `reviewer_username`             | string         | no       | Returns merge requests which have the user as a [reviewer](../user/project/merge_requests/getting_started.md#reviewer) with the given `username`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer. Mutually exclusive with `reviewer_id`. |
| `my_reaction_emoji`             | string         | no       | Return merge requests reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction. _([Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/14016) in GitLab 10.0)_. |
| `source_branch`                 | string         | no       | Return merge requests with the given source branch.                                                                             |
| `target_branch`                 | string         | no       | Return merge requests with the given target branch.                                                                             |
| `search`                        | string         | no       | Search merge requests against their `title` and `description`. |
| `non_archived`                  | boolean        | no       | Return merge requests from non archived projects only. Default is true. _(Introduced in [GitLab 12.8](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/23809))_.  |
| `not`                           | Hash           | no       | Return merge requests that do not match the parameters supplied. Accepts: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `reviewer_id`, `reviewer_username`, `my_reaction_emoji`. |

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 3,
    "title": "test1",
    "description": "fixed login page css paddings",
    "state": "merged",
    "merged_by": {
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merged_at": "2018-09-07T11:16:17.520Z",
    "closed_by": null,
    "closed_at": null,
    "created_at": "2017-04-29T08:46:00Z",
    "updated_at": "2017-04-29T08:46:00Z",
    "target_branch": "master",
    "source_branch": "test1",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignee": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignees": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/axel.block"
    }],
    "reviewers": [{
      "id": 2,
      "name": "Sam Bauch",
      "username": "kenyatta_oconnell",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/956c92487c6f6f7616b536927e22c9a0?s=80&d=identicon",
      "web_url": "http://gitlab.example.com//kenyatta_oconnell"
    }],
    "source_project_id": 2,
    "target_project_id": 3,
    "labels": [
      "Community contribution",
      "Manage"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 5,
      "iid": 1,
      "project_id": 3,
      "title": "v2.0",
      "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
      "state": "closed",
      "created_at": "2015-02-02T19:49:26.013Z",
      "updated_at": "2015-02-02T19:49:26.013Z",
      "due_date": "2018-10-22",
      "start_date": "2018-09-08",
      "web_url": "gitlab.example.com/my-group/my-project/milestones/1"
    },
    "merge_when_pipeline_succeeds": true,
    "merge_status": "can_be_merged",
    "sha": "8888888888888888888888888888888888888888",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 1,
    "discussion_locked": null,
    "should_remove_source_branch": true,
    "force_remove_source_branch": false,
    "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
    "references": {
      "short": "!1",
      "relative": "my-project!1",
      "full": "my-group/my-project!1"
    },
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "squash": false,
    "task_completion_status":{
      "count":0,
      "completed_count":0
    },
    "has_conflicts": false,
    "blocking_discussions_resolved": true
  }
]
```

Users on GitLab Premium or higher also see
the `approvals_before_merge` parameter:

```json
[
  {
    "id": 1,
    "title": "test1",
    "approvals_before_merge": null
    ...
  }
]
```

## Get single MR

Shows information about a single merge request.

**Note**: the `changes_count` value in the response is a string, not an
integer. This is because when an MR has too many changes to display and store,
it is capped at 1,000. In that case, the API returns the string
`"1000+"` for the changes count.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid
```

Parameters:

| Attribute                        | Type           | Required | Description                                                                                                      |
|----------------------------------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`                             | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid`              | integer        | yes      | The internal ID of the merge request.                                                                            |
| `render_html`                    | integer        | no       | If `true` response includes rendered HTML for title and description.                                             |
| `include_diverged_commits_count` | boolean        | no       | If `true` response includes the commits behind the target branch.                                                |
| `include_rebase_in_progress`     | boolean        | no       | If `true` response includes whether a rebase operation is in progress.                                           |

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "master",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "user" : {
    "can_merge" : false
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "id": 2,
    "name": "Sam Bauch",
    "username": "kenyatta_oconnell",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/956c92487c6f6f7616b536927e22c9a0?s=80&d=identicon",
    "web_url": "http://gitlab.example.com//kenyatta_oconnell"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "merge_error": null,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "rebase_in_progress": false,
  "first_contribution": false,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  },
  "has_conflicts": false,
  "blocking_discussions_resolved": true
}
```

Users on GitLab Premium also see
the `approvals_before_merge` parameter:

```json
{
  "id": 1,
  "title": "test1",
  "approvals_before_merge": null
  ...
}
```

The `diff_refs` in the response correspond to the latest diff version of the merge request.

## Get single MR participants

Get a list of merge request participants.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/participants
```

Parameters:

| Attribute                        | Type           | Required | Description                                                                                                      |
|----------------------------------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`                             | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid`              | integer        | yes      | The internal ID of the merge request.                                                                            |

```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://localhost/user1"
  },
  {
    "id": 2,
    "name": "John Doe2",
    "username": "user2",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80&d=identicon",
    "web_url": "http://localhost/user2"
  }
]
```

## Get single MR commits

Get a list of merge request commits.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/commits
```

Parameters:

| Attribute                        | Type           | Required | Description                                                                                                      |
|----------------------------------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`                             | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid`              | integer        | yes      | The internal ID of the merge request.                                                                            |

```json
[
  {
    "id": "ed899a2f4b50b4370feeea94676502b42383c746",
    "short_id": "ed899a2f4b5",
    "title": "Replace sanitize with escape once",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "created_at": "2012-09-20T11:50:22+03:00",
    "message": "Replace sanitize with escape once"
  },
  {
    "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
    "short_id": "6104942438c",
    "title": "Sanitize for network graph",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "created_at": "2012-09-20T09:06:12+03:00",
    "message": "Sanitize for network graph"
  }
]
```

## Get single MR changes

Shows information about the merge request including its files and changes.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/changes
```

Parameters:

| Attribute                        | Type           | Required | Description                                                                                                      |
|----------------------------------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`                             | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid`              | integer        | yes      | The internal ID of the merge request.                                                                            |
| `access_raw_diffs`               | boolean        | no       | Retrieve change diffs via Gitaly.                                                                 |

```json
{
  "id": 21,
  "iid": 1,
  "project_id": 4,
  "title": "Blanditiis beatae suscipit hic assumenda et molestias nisi asperiores repellat et.",
  "state": "reopened",
  "created_at": "2015-02-02T19:49:39.159Z",
  "updated_at": "2015-02-02T20:08:49.959Z",
  "target_branch": "secret_token",
  "source_branch": "version-1-9",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "name": "Chad Hamill",
    "username": "jarrett",
    "id": 5,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/b95567800f828948baf5f4160ebb2473?s=40&d=identicon",
    "web_url" : "https://gitlab.example.com/jarrett"
  },
  "assignee": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40&d=identicon",
    "web_url" : "https://gitlab.example.com/root"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 4,
  "target_project_id": 4,
  "labels": [ ],
  "description": "Qui voluptatibus placeat ipsa alias quasi. Deleniti rem ut sint. Optio velit qui distinctio.",
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 4,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": null
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "subscribed" : true,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "changes_count": "1",
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "squash": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "discussion_locked": false,
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "task_completion_status":{
    "count":0,
    "completed_count":0
  },
  "changes": [
    {
    "old_path": "VERSION",
    "new_path": "VERSION",
    "a_mode": "100644",
    "b_mode": "100644",
    "diff": "--- a/VERSION\ +++ b/VERSION\ @@ -1 +1 @@\ -1.9.7\ +1.9.8",
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false
    }
  ],
  "overflow": false
}
```

## List MR pipelines

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/15454) in GitLab 10.5.

Get a list of merge request pipelines.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/pipelines
```

Parameters:

| Attribute                        | Type           | Required | Description                                                                                                      |
|----------------------------------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`                             | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid`              | integer        | yes      | The internal ID of the merge request.                                                                            |

```json
[
  {
    "id": 77,
    "sha": "959e04d7c7a30600c894bd3c0cd0e1ce7f42c11d",
    "ref": "master",
    "status": "success"
  }
]
```

## Create MR Pipeline

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/31722) in GitLab 12.3.

Create a new [pipeline for a merge request](../ci/pipelines/merge_request_pipelines.md).
A pipeline created via this endpoint doesn't run a regular branch/tag pipeline.
It requires `.gitlab-ci.yml` to be configured with `only: [merge_requests]` to create jobs.

The new pipeline can be:

- A detached merge request pipeline.
- A [pipeline for merged results](../ci/pipelines/pipelines_for_merged_results.md)
  if the [project setting is enabled](../ci/pipelines/pipelines_for_merged_results.md#enable-pipelines-for-merged-results).

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/pipelines
```

Parameters:

| Attribute                        | Type           | Required | Description                                                                                                      |
|----------------------------------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`                             | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid`              | integer        | yes      | The internal ID of the merge request.                                                                            |

```json
{
  "id": 2,
  "sha": "b83d6e391c22777fca1ed3012fce84f633d7fed0",
  "ref": "refs/merge-requests/1/head",
  "status": "pending",
  "web_url": "http://localhost/user1/project1/pipelines/2",
  "before_sha": "0000000000000000000000000000000000000000",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://example.com"
  },
  "created_at": "2019-09-04T19:20:18.267Z",
  "updated_at": "2019-09-04T19:20:18.459Z",
  "started_at": null,
  "finished_at": null,
  "committed_at": null,
  "duration": null,
  "coverage": null,
  "detailed_status": {
    "icon": "status_pending",
    "text": "pending",
    "label": "pending",
    "group": "pending",
    "tooltip": "pending",
    "has_details": false,
    "details_path": "/user1/project1/pipelines/2",
    "illustration": null,
    "favicon": "/assets/ci_favicons/favicon_status_pending-5bdf338420e5221ca24353b6bff1c9367189588750632e9a871b7af09ff6a2ae.png"
  }
}
```

## Create MR

Creates a new merge request.

```plaintext
POST /projects/:id/merge_requests
```

| Attribute                  | Type    | Required | Description                                                                     |
| ---------                  | ----    | -------- | -----------                                                                     |
| `id`                       | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `source_branch`            | string  | yes      | The source branch.                                                               |
| `target_branch`            | string  | yes      | The target branch.                                                               |
| `title`                    | string  | yes      | Title of MR.                                                                     |
| `assignee_id`              | integer | no       | Assignee user ID.                                                                |
| `assignee_ids`             | integer array | no | The ID of the user(s) to assign the MR to. Set to `0` or provide an empty value to unassign all assignees. |
| `reviewer_ids`             | integer array | no | The ID of the user(s) added as a reviewer to the MR. If set to `0` or left empty, no reviewers are added.  |
| `description`              | string  | no       | Description of MR. Limited to 1,048,576 characters. |
| `target_project_id`        | integer | no       | The target project (numeric ID).                                                 |
| `labels`                   | string  | no       | Labels for MR as a comma-separated list.                                         |
| `milestone_id`             | integer | no       | The global ID of a milestone.                                                           |
| `remove_source_branch`     | boolean | no       | Flag indicating if a merge request should remove the source branch when merging. |
| `allow_collaboration`      | boolean | no       | Allow commits from members who can merge to the target branch.                   |
| `allow_maintainer_to_push` | boolean | no       | Deprecated, see `allow_collaboration`.                                             |
| `squash`                   | boolean | no       | Squash commits into a single commit when merging.                                |

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "master",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "merge_error": null,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

Users of [GitLab Premium or higher](https://about.gitlab.com/pricing/) also see
the `approvals_before_merge` parameter:

```json
{
  "id": 1,
  "title": "test1",
  "approvals_before_merge": null
  ...
}
```

## Update MR

Updates an existing merge request. You can change the target branch, title, or even close the MR.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid
```

| Attribute                  | Type    | Required | Description                                                                     |
| ---------                  | ----    | -------- | -----------                                                                     |
| `id`                       | integer/string | yes  | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid`        | integer | yes      | The ID of a merge request.                                                       |
| `target_branch`            | string  | no       | The target branch.                                                               |
| `title`                    | string  | no       | Title of MR.                                                                     |
| `assignee_id`              | integer | no       | The ID of the user to assign the merge request to. Set to `0` or provide an empty value to unassign all assignees.  |
| `assignee_ids`             | integer array | no | The ID of the user(s) to assign the MR to. Set to `0` or provide an empty value to unassign all assignees.  |
| `reviewer_ids`             | integer array | no | The ID of the user(s) set as a reviewer to the MR. Set the value to `0` or provide an empty value to unset all reviewers.  |
| `milestone_id`             | integer | no       | The global ID of a milestone to assign the merge request to. Set to `0` or provide an empty value to unassign a milestone.|
| `labels`                   | string  | no       | Comma-separated label names for a merge request. Set to an empty string to unassign all labels.                    |
| `add_labels`               | string  | no       | Comma-separated label names to add to a merge request.                          |
| `remove_labels`            | string  | no       | Comma-separated label names to remove from a merge request.                     |
| `description`              | string  | no       | Description of MR. Limited to 1,048,576 characters. |
| `state_event`              | string  | no       | New state (close/reopen).                                                        |
| `remove_source_branch`     | boolean | no       | Flag indicating if a merge request should remove the source branch when merging. |
| `squash`                   | boolean | no       | Squash commits into a single commit when merging. |
| `discussion_locked`        | boolean | no       | Flag indicating if the merge request's discussion is locked. If the discussion is locked only project members can add, edit or resolve comments. |
| `allow_collaboration`      | boolean | no       | Allow commits from members who can merge to the target branch.                   |
| `allow_maintainer_to_push` | boolean | no       | Deprecated, see `allow_collaboration`.                                             |

Must include at least one non-required attribute from above.

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "master",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "merge_error": null,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

Users on GitLab Premium or higher also see
the `approvals_before_merge` parameter:

```json
{
  "id": 1,
  "title": "test1",
  "approvals_before_merge": null
  ...
}
```

## Delete a merge request

Only for administrators and project owners. Deletes the merge request in question.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid
```

| Attribute | Type    | Required | Description                          |
| --------- | ----    | -------- | -----------                          |
| `id`      | integer/string  | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/4/merge_requests/85"
```

## Accept MR

Merge changes submitted with MR using this API.

If a merge request is unable to be accepted (such as Draft, Closed, Pipeline Pending Completion, or Failed while requiring Success) - you receive a `405` and the error message 'Method Not Allowed'

If it has some conflicts and can not be merged - you receive a `406` and the error message 'Branch cannot be merged'

If the `sha` parameter is passed and does not match the HEAD of the source - you receive a `409` and the error message 'SHA does not match HEAD of source branch'

If you don't have permissions to accept this merge request - you receive a `401`

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/merge
```

Parameters:

| Attribute                      | Type           | Required | Description                                                                                                      |
|--------------------------------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`                           | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid`            | integer        | yes      | The internal ID of the merge request.                                                                            |
| `merge_commit_message`         | string         | no       | Custom merge commit message.                                                                                     |
| `squash_commit_message`        | string         | no       | Custom squash commit message.                                                                                    |
| `squash`                       | boolean        | no       | If `true` the commits are squashed into a single commit on merge.                                    |
| `should_remove_source_branch`  | boolean        | no       | If `true` removes the source branch.                                                                             |
| `merge_when_pipeline_succeeds` | boolean        | no       | If `true` the MR is merged when the pipeline succeeds.                                                           |
| `sha`                          | string         | no       | If present, then this SHA must match the HEAD of the source branch, otherwise the merge fails.                   |

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "master",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "merge_error": null,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

Users on GitLab Premium also see
the `approvals_before_merge` parameter:

```json
{
  "id": 1,
  "title": "test1",
  "approvals_before_merge": null
  ...
}
```

## Merge to default merge ref path

Merge the changes between the merge request source and target branches into `refs/merge-requests/:iid/merge`
ref, of the target project repository, if possible. This ref has the state the target branch would have if
a regular merge action was taken.

This is not a regular merge action given it doesn't change the merge request target branch state in any manner.

This ref (`refs/merge-requests/:iid/merge`) isn't necessarily overwritten when submitting
requests to this API, though it makes sure the ref has the latest possible state.

If the merge request has conflicts, is empty or already merged, you receive a `400` and a descriptive error message.

It returns the HEAD commit of `refs/merge-requests/:iid/merge` in the response body in case of `200`.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/merge_ref
```

Parameters:

| Attribute                      | Type           | Required | Description                                                                                                      |
|--------------------------------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`                           | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid`            | integer        | yes      | The internal ID of the merge request.                                                                            |

```json
{
  "commit_id": "854a3a7a17acbcc0bbbea170986df1eb60435f34"
}
```

## Cancel Merge When Pipeline Succeeds

- If you don't have permissions to accept this merge request - you receive a `HTTP 401 Unauthorized`.
- If the merge request is already merged or closed - you receive a `HTTP 405 Method Not Allowed` and the error message 'Method Not Allowed'.
- In case the merge request is not set to be merged when the pipeline succeeds, you also receive a `HTTP 406 Not Acceptable` error.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/cancel_merge_when_pipeline_succeeds
```

Parameters:

| Attribute                      | Type           | Required | Description                                                                                                      |
|--------------------------------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`                           | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid`            | integer        | yes      | The internal ID of the merge request.                                                                            |

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "master",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": false,
  "merge_status": "can_be_merged",
  "merge_error": null,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

Users on GitLab Premium or higher also see
the `approvals_before_merge` parameter:

```json
{
  "id": 1,
  "title": "test1",
  "approvals_before_merge": null
  ...
}
```

## Rebase a merge request

Automatically rebase the `source_branch` of the merge request against its
`target_branch`.

If you don't have permissions to push to the merge request's source branch -
you receive a `403 Forbidden` response.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/rebase
```

| Attribute           | Type    | Required | Description                          |
| ---------           | ----    | -------- | -----------                          |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user.                  |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request. |
| `skip_ci`           | boolean | no       | Set to `true` to skip creating a CI pipeline. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/76/merge_requests/1/rebase"
```

This is an asynchronous request. The API returns a `HTTP 202 Accepted` response
if the request is enqueued successfully, with a response containing:

```json
{
  "rebase_in_progress": true
}
```

You can poll the [Get single MR](#get-single-mr) endpoint with the
`include_rebase_in_progress` parameter to check the status of the
asynchronous request.

If the rebase operation is ongoing, the response includes the following:

```json
{
  "rebase_in_progress": true,
  "merge_error": null
}
```

After the rebase operation has completed successfully, the response includes
the following:

```json
{
  "rebase_in_progress": false,
  "merge_error": null
}
```

If the rebase operation fails, the response includes the following:

```json
{
  "rebase_in_progress": false,
  "merge_error": "Rebase failed. Please rebase locally"
}
```

## Comments on merge requests

Comments are done via the [notes](notes.md) resource.

## List issues that close on merge

Get all the issues that would be closed by merging the provided merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/closes_issues
```

| Attribute           | Type    | Required | Description                          |
| ---------           | ----    | -------- | -----------                          |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user.                  |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/76/merge_requests/1/closes_issues"
```

Example response when the GitLab issue tracker is used:

```json
[
   {
      "state" : "opened",
      "description" : "Ratione dolores corrupti mollitia soluta quia.",
      "author" : {
         "state" : "active",
         "id" : 18,
         "web_url" : "https://gitlab.example.com/eileen.lowe",
         "name" : "Alexandra Bashirian",
         "avatar_url" : null,
         "username" : "eileen.lowe"
      },
      "milestone" : {
         "project_id" : 1,
         "description" : "Ducimus nam enim ex consequatur cumque ratione.",
         "state" : "closed",
         "due_date" : null,
         "iid" : 2,
         "created_at" : "2016-01-04T15:31:39.996Z",
         "title" : "v4.0",
         "id" : 17,
         "updated_at" : "2016-01-04T15:31:39.996Z"
      },
      "project_id" : 1,
      "assignee" : {
         "state" : "active",
         "id" : 1,
         "name" : "Administrator",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root"
      },
      "updated_at" : "2016-01-04T15:31:51.081Z",
      "id" : 76,
      "title" : "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
      "created_at" : "2016-01-04T15:31:51.081Z",
      "iid" : 6,
      "labels" : [],
      "user_notes_count": 1,
      "changes_count": "1"
   }
]
```

Example response when an external issue tracker (for example, Jira) is used:

```json
[
   {
       "id" : "PROJECT-123",
       "title" : "Title of this issue"
   }
]
```

## Subscribe to a merge request

Subscribes the authenticated user to a merge request to receive notification. If the user is already subscribed to the merge request, the
status code `HTTP 304 Not Modified` is returned.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/subscribe
```

| Attribute           | Type    | Required | Description                 |
| ---------           | ----    | -------- | -----------                 |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user.         |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/17/subscribe"
```

Example response:

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "master",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

Users on GitLab Premium also see
the `approvals_before_merge` parameter:

```json
{
  "id": 1,
  "title": "test1",
  "approvals_before_merge": null
  ...
}
```

## Unsubscribe from a merge request

Unsubscribes the authenticated user from a merge request to not receive
notifications from that merge request. If the user is
not subscribed to the merge request, the status code `HTTP 304 Not Modified` is returned.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/unsubscribe
```

| Attribute           | Type    | Required | Description                          |
| ---------           | ----    | -------- | -----------                          |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user.                  |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/17/unsubscribe"
```

Example response:

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "master",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

Users on GitLab Premium or higher also see
the `approvals_before_merge` parameter:

```json
{
  "id": 1,
  "title": "test1",
  "approvals_before_merge": null
  ...
}
```

## Create a to-do item

Manually creates a to-do item for the current user on a merge request.
If there already exists a to-do item for the user on that merge request,
status code `HTTP 304 Not Modified` is returned.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/todo
```

| Attribute           | Type    | Required | Description                          |
| ---------           | ----    | -------- | -----------                          |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user.                  |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/27/todo"
```

Example response:

```json
{
  "id": 113,
  "project": {
    "id": 3,
    "name": "GitLab CI/CD",
    "name_with_namespace": "GitLab Org / GitLab CI/CD",
    "path": "gitlab-ci",
    "path_with_namespace": "gitlab-org/gitlab-ci"
  },
  "author": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/root"
  },
  "action_name": "marked",
  "target_type": "MergeRequest",
  "target": {
    "id": 27,
    "iid": 7,
    "project_id": 3,
    "title": "Et voluptas laudantium minus nihil recusandae ut accusamus earum aut non.",
    "description": "Veniam sunt nihil modi earum cumque illum delectus. Nihil ad quis distinctio quia. Autem eligendi at quibusdam repellendus.",
    "state": "merged",
    "created_at": "2016-06-17T07:48:04.330Z",
    "updated_at": "2016-07-01T11:14:15.537Z",
    "target_branch": "allow_regex_for_project_skip_ref",
    "source_branch": "backup",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "name": "Jarret O'Keefe",
      "username": "francisca",
      "id": 14,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a7fa515d53450023c83d62986d0658a8?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/francisca",
      "discussion_locked": false
    },
    "assignee": {
      "name": "Dr. Gabrielle Strosin",
      "username": "barrett.krajcik",
      "id": 4,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/733005fcd7e6df12d2d8580171ccb966?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/barrett.krajcik"
    },
    "assignees": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/axel.block"
    }],
    "reviewers": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/axel.block"
    }],
    "source_project_id": 3,
    "target_project_id": 3,
    "labels": [],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 27,
      "iid": 2,
      "project_id": 3,
      "title": "v1.0",
      "description": "Quis ea accusantium animi hic fuga assumenda.",
      "state": "active",
      "created_at": "2016-06-17T07:47:33.840Z",
      "updated_at": "2016-06-17T07:47:33.840Z",
      "due_date": null
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "unchecked",
    "subscribed": true,
    "sha": "8888888888888888888888888888888888888888",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 7,
    "changes_count": "1",
    "should_remove_source_branch": true,
    "force_remove_source_branch": false,
    "squash": false,
    "web_url": "http://example.com/my-group/my-project/merge_requests/1",
    "references": {
      "short": "!1",
      "relative": "!1",
      "full": "my-group/my-project!1"
    }
  },
  "target_url": "https://gitlab.example.com/gitlab-org/gitlab-ci/merge_requests/7",
  "body": "Et voluptas laudantium minus nihil recusandae ut accusamus earum aut non.",
  "state": "pending",
  "created_at": "2016-07-01T11:14:15.530Z"
}
```

## Get MR diff versions

Get a list of merge request diff versions. For an explanation of the SHAs in the response,
read [SHAs in the API response](#shas-in-the-api-response).

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/versions
```

| Attribute           | Type    | Required | Description                 |
| ---------           | ------- | -------- | ---------------------       |
| `id`                | String  | yes      | The ID of the project.       |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/versions"
```

Example response:

```json
[{
  "id": 110,
  "head_commit_sha": "33e2ee8579fda5bc36accc9c6fbd0b4fefda9e30",
  "base_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "start_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "created_at": "2016-07-26T14:44:48.926Z",
  "merge_request_id": 105,
  "state": "collected",
  "real_size": "1"
}, {
  "id": 108,
  "head_commit_sha": "3eed087b29835c48015768f839d76e5ea8f07a24",
  "base_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "start_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "created_at": "2016-07-25T14:21:33.028Z",
  "merge_request_id": 105,
  "state": "collected",
  "real_size": "1"
}]
```

### SHAs in the API response

- `head_commit_sha`: The HEAD commit of the source branch.
- `base_commit_sha`: The merge-base commit SHA between the source branch and the target branches.
- `start_commit_sha`: The HEAD commit SHA of the target branch when this version of the diff was created.

## Get a single MR diff version

Get a single merge request diff version. For an explanation of the SHAs in the response,
read [SHAs in the API response](#shas-in-the-api-response).

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/versions/:version_id
```

| Attribute           | Type    | Required | Description                              |
| ---------           | ------- | -------- | ---------------------                    |
| `id`                | String  | yes      | The ID of the project.                    |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request.     |
| `version_id`        | integer | yes      | The ID of the merge request diff version. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/versions/1"
```

Example response:

```json
{
  "id": 110,
  "head_commit_sha": "33e2ee8579fda5bc36accc9c6fbd0b4fefda9e30",
  "base_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "start_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "created_at": "2016-07-26T14:44:48.926Z",
  "merge_request_id": 105,
  "state": "collected",
  "real_size": "1",
  "commits": [{
    "id": "33e2ee8579fda5bc36accc9c6fbd0b4fefda9e30",
    "short_id": "33e2ee85",
    "title": "Change year to 2018",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "created_at": "2016-07-26T17:44:29.000+03:00",
    "message": "Change year to 2018"
  }, {
    "id": "aa24655de48b36335556ac8a3cd8bb521f977cbd",
    "short_id": "aa24655d",
    "title": "Update LICENSE",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "created_at": "2016-07-25T17:21:53.000+03:00",
    "message": "Update LICENSE"
  }, {
    "id": "3eed087b29835c48015768f839d76e5ea8f07a24",
    "short_id": "3eed087b",
    "title": "Add license",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "created_at": "2016-07-25T17:21:20.000+03:00",
    "message": "Add license"
  }],
  "diffs": [{
    "old_path": "LICENSE",
    "new_path": "LICENSE",
    "a_mode": "0",
    "b_mode": "100644",
    "diff": "--- /dev/null\n+++ b/LICENSE\n@@ -0,0 +1,21 @@\n+The MIT License (MIT)\n+\n+Copyright (c) 2018 Administrator\n+\n+Permission is hereby granted, free of charge, to any person obtaining a copy\n+of this software and associated documentation files (the \"Software\"), to deal\n+in the Software without restriction, including without limitation the rights\n+to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\n+copies of the Software, and to permit persons to whom the Software is\n+furnished to do so, subject to the following conditions:\n+\n+The above copyright notice and this permission notice shall be included in all\n+copies or substantial portions of the Software.\n+\n+THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n+IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\n+FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\n+AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\n+LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\n+OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\n+SOFTWARE.\n",
    "new_file": true,
    "renamed_file": false,
    "deleted_file": false
  }]
}
```

## Set a time estimate for a merge request

Sets an estimated time of work for this merge request.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/time_estimate
```

| Attribute           | Type    | Required | Description                              |
| ---------           | ----    | -------- | -----------                              |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user.                      |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request.     |
| `duration`          | string  | yes      | The duration in human format, such as `3h30m`. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/time_estimate?duration=3h30m"
```

Example response:

```json
{
  "human_time_estimate": "3h 30m",
  "human_total_time_spent": null,
  "time_estimate": 12600,
  "total_time_spent": 0
}
```

## Reset the time estimate for a merge request

Resets the estimated time for this merge request to 0 seconds.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/reset_time_estimate
```

| Attribute           | Type    | Required | Description                                  |
| ---------           | ----    | -------- | -----------                                  |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user.                          |
| `merge_request_iid` | integer | yes      | The internal ID of a project's merge_request. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/reset_time_estimate"
```

Example response:

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": null,
  "time_estimate": 0,
  "total_time_spent": 0
}
```

## Add spent time for a merge request

Adds spent time for this merge request.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/add_spent_time
```

| Attribute           | Type    | Required | Description                              |
| ---------           | ----    | -------- | -----------                              |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user.                      |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request.     |
| `duration`          | string  | yes      | The duration in human format, such as `3h30m` |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/add_spent_time?duration=1h"
```

Example response:

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": "1h",
  "time_estimate": 0,
  "total_time_spent": 3600
}
```

## Reset spent time for a merge request

Resets the total spent time for this merge request to 0 seconds.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/reset_spent_time
```

| Attribute           | Type    | Required | Description                                  |
| ---------           | ----    | -------- | -----------                                  |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user.                          |
| `merge_request_iid` | integer | yes      | The internal ID of a project's merge_request. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/reset_spent_time"
```

Example response:

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": null,
  "time_estimate": 0,
  "total_time_spent": 0
}
```

## Get time tracking stats

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/time_stats
```

| Attribute           | Type    | Required | Description                          |
| ---------           | ----    | -------- | -----------                          |
| `id`                | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user.                  |
| `merge_request_iid` | integer | yes      | The internal ID of the merge request. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/time_stats"
```

Example response:

```json
{
  "human_time_estimate": "2h",
  "human_total_time_spent": "1h",
  "time_estimate": 7200,
  "total_time_spent": 3600
}
```

## Approvals

For approvals, please see [Merge Request Approvals](merge_request_approvals.md)

## List merge request state events

To track which state was set, who did it, and when it happened, check out
[Resource state events API](resource_state_events.md#merge-requests).
