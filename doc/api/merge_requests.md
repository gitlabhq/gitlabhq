---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Merge requests API **(FREE)**

> - `reference` was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20354) in GitLab 12.7.
> - `draft` was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63473) as a replacement for `work_in_progress` in GitLab 14.0.
> - `merged_by` was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/350534) in GitLab 14.7.
> - `merge_user` was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/349031) as an eventual replacement for `merged_by` in GitLab 14.7.
> - `merge_status` was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204) in favor of `detailed_merge_status` in GitLab 15.6.
> - `with_merge_status_recheck` [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115948) in GitLab 15.11  [with a flag](../administration/feature_flags.md) named `restrict_merge_status_recheck` to be ignored for requests from users insufficient permissions. Disabled by default.
> - `approvals_before_merge` was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119503) in GitLab 16.0.

Every API call to merge requests must be authenticated.

## Removals in API v5

The `approvals_before_merge` attribute has been deprecated, and is scheduled to be removed
in API v5 in favor of the [Merge request approvals API](merge_request_approvals.md).

## List merge requests

Get all merge requests the authenticated user has access to. By
default it returns only merge requests created by the current user. To
get all merge requests, use parameter `scope=all`.

The `state` parameter can be used to get only merge requests with a
given state (`opened`, `closed`, `locked`, or `merged`) or all of them (`all`).
It should be noted that when searching by `locked` it mostly returns no results
as it is a short-lived, transitional state. The pagination parameters `page` and
`per_page` can be used to restrict the list of merge requests.

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

Supported attributes:

| Attribute                       | Type           | Required | Description |
| ------------------------------- | -------------- | -------- | ----------- |
| `approved_by_ids` **(PREMIUM)** | integer array  | **{dotted-circle}** No       | Returns merge requests which have been approved by all the users with the given `id`. Maximum of 5. `None` returns merge requests with no approvals. `Any` returns merge requests with an approval. |
| `approver_ids` **(PREMIUM)**    | integer array  | **{dotted-circle}** No       | Returns merge requests which have specified all the users with the given `id` as individual approvers. `None` returns merge requests without approvers. `Any` returns merge requests with an approver. |
| `approved`                      | string         | **{dotted-circle}** No       | Filters merge requests by their `approved` status. `yes` returns only approved merge requests. `no` returns only non-approved merge requests. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/3159) in GitLab 15.11. Available only when the feature flag `mr_approved_filter` is enabled. |
| `assignee_id`                   | integer        | **{dotted-circle}** No       | Returns merge requests assigned to the given user `id`. `None` returns unassigned merge requests. `Any` returns merge requests with an assignee. |
| `author_id`                     | integer        | **{dotted-circle}** No       | Returns merge requests created by the given user `id`. Mutually exclusive with `author_username`. Combine with `scope=all` or `scope=assigned_to_me`. |
| `author_username`               | string         | **{dotted-circle}** No       | Returns merge requests created by the given `username`. Mutually exclusive with `author_id`. |
| `created_after`                 | datetime       | **{dotted-circle}** No       | Returns merge requests created on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `created_before`                | datetime       | **{dotted-circle}** No       | Returns merge requests created on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `deployed_after`                | datetime       | **{dotted-circle}** No       | Returns merge requests deployed after the given date/time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `deployed_before`               | datetime       | **{dotted-circle}** No       | Returns merge requests deployed before the given date/time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `environment`                   | string         | **{dotted-circle}** No       | Returns merge requests deployed to the given environment. |
| `in`                            | string         | **{dotted-circle}** No       | Modify the scope of the `search` attribute. `title`, `description`, or a string joining them with comma. Default is `title,description`. |
| `labels`                        | string         | **{dotted-circle}** No       | Returns merge requests matching a comma-separated list of labels. `None` lists all merge requests with no labels. `Any` lists all merge requests with at least one label. Predefined names are case-insensitive. |
| `milestone`                     | string         | **{dotted-circle}** No       | Returns merge requests for a specific milestone. `None` returns merge requests with no milestone. `Any` returns merge requests that have an assigned milestone. |
| `my_reaction_emoji`             | string         | **{dotted-circle}** No       | Returns merge requests reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction. |
| `not`                           | Hash           | **{dotted-circle}** No       | Returns merge requests that do not match the parameters supplied. Accepts: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `reviewer_id`, `reviewer_username`, `my_reaction_emoji`. |
| `order_by`                      | string         | **{dotted-circle}** No       | Returns requests ordered by `created_at`, `title`, or `updated_at` fields. Default is `created_at`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/331625) in GitLab 14.8.|
| `reviewer_id`                   | integer        | **{dotted-circle}** No       | Returns merge requests which have the user as a [reviewer](../user/project/merge_requests/reviews/index.md) with the given user `id`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer. Mutually exclusive with `reviewer_username`. |
| `reviewer_username`             | string         | **{dotted-circle}** No       | Returns merge requests which have the user as a [reviewer](../user/project/merge_requests/reviews/index.md) with the given `username`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer. Mutually exclusive with `reviewer_id`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49341) in GitLab 13.8. |
| `scope`                         | string         | **{dotted-circle}** No       | Returns merge requests for the given scope: `created_by_me`, `assigned_to_me` or `all`. Defaults to `created_by_me`. |
| `search`                        | string         | **{dotted-circle}** No       | Search merge requests against their `title` and `description`. |
| `sort`                          | string         | **{dotted-circle}** No       | Returns requests sorted in `asc` or `desc` order. Default is `desc`. |
| `source_branch`                 | string         | **{dotted-circle}** No       | Returns merge requests with the given source branch. |
| `state`                         | string         | **{dotted-circle}** No       | Returns all merge requests or just those that are `opened`, `closed`, `locked`, or `merged`. |
| `target_branch`                 | string         | **{dotted-circle}** No       | Returns merge requests with the given target branch. |
| `updated_after`                 | datetime       | **{dotted-circle}** No       | Returns merge requests updated on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `updated_before`                | datetime       | **{dotted-circle}** No       | Returns merge requests updated on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `view`                          | string         | **{dotted-circle}** No       | If `simple`, returns the `iid`, URL, title, description, and basic state of merge request. |
| `with_labels_details`           | boolean        | **{dotted-circle}** No       | If `true`, response returns more details for each label in labels field: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. Default is `false`. |
| `with_merge_status_recheck`     | boolean        | **{dotted-circle}** No       | If `true`, this projection requests (but does not guarantee) that the `merge_status` field be recalculated asynchronously. Default is `false`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/31890) in GitLab 13.0. In GitLab 15.11 and later, enable the `restrict_merge_status_recheck` feature [flag](../administration/feature_flags.md) for this attribute to be ignored when requested by users without at least the Developer role. |
| `wip`                           | string         | **{dotted-circle}** No       | Filter merge requests against their `wip` status. `yes` to return *only* draft merge requests, `no` to return *non-draft* merge requests. |

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 3,
    "title": "test1",
    "description": "fixed login page css paddings",
    "state": "merged",
    "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merge_user": {
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
    "detailed_merge_status": "not_open",
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

### Merge requests list response notes

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/31890) in GitLab 13.0, listing merge requests may
  not proactively update `merge_status` (which also affects the `has_conflicts`), as this can be an expensive operation.
  If you need the value of these fields from this endpoint, set the `with_merge_status_recheck` parameter to
  `true` in the query.
- For notes on merge request object fields, read [Single merge request response notes](#single-merge-request-response-notes).

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

`project_id` represents the ID of the project where the merge request resides.
`project_id` always equals `target_project_id`.

In the case of a merge request from the same project,
`source_project_id`, `target_project_id` and `project_id`
are the same. In the case of a merge request from a fork,
`target_project_id` and `project_id` are the same and
`source_project_id` is the fork project's ID.

Supported attributes:

| Attribute                       | Type           | Required | Description |
| ------------------------------- | -------------- | -------- | ----------- |
| `id`                            | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `approved_by_ids` **(PREMIUM)** | integer array  | **{dotted-circle}** No       | Returns merge requests which have been approved by all the users with the given `id`, with a maximum of 5. `None` returns merge requests with no approvals. `Any` returns merge requests with an approval. |
| `approver_ids` **(PREMIUM)**    | integer array  | **{dotted-circle}** No       | Returns merge requests which have specified all the users with the given `id` as individual approvers. `None` returns merge requests without approvers. `Any` returns merge requests with an approver. |
| `approved`                      | string         | **{dotted-circle}** No       | Filters merge requests by their `approved` status. `yes` returns only approved merge requests. `no` returns only non-approved merge requests. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/3159) in GitLab 15.11. Available only when the feature flag `mr_approved_filter` is enabled. |
| `assignee_id`                   | integer        | **{dotted-circle}** No       | Returns merge requests assigned to the given user `id`. `None` returns unassigned merge requests. `Any` returns merge requests with an assignee. |
| `author_id`                     | integer        | **{dotted-circle}** No       | Returns merge requests created by the given user `id`. Mutually exclusive with `author_username`. |
| `author_username`               | string         | **{dotted-circle}** No       | Returns merge requests created by the given `username`. Mutually exclusive with `author_id`. |
| `created_after`                 | datetime       | **{dotted-circle}** No       | Returns merge requests created on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `created_before`                | datetime       | **{dotted-circle}** No       | Returns merge requests created on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `environment`                   | string         | **{dotted-circle}** No       | Returns merge requests deployed to the given environment. |
| `iids[]`                        | integer array  | **{dotted-circle}** No       | Returns the request having the given `iid`. |
| `labels`                        | string         | **{dotted-circle}** No       | Returns merge requests matching a comma-separated list of labels. `None` lists all merge requests with no labels. `Any` lists all merge requests with at least one label. Predefined names are case-insensitive. |
| `milestone`                     | string         | **{dotted-circle}** No       | Returns merge requests for a specific milestone. `None` returns merge requests with no milestone. `Any` returns merge requests that have an assigned milestone. |
| `my_reaction_emoji`             | string         | **{dotted-circle}** No       | Returns merge requests reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction. |
| `not`                           | Hash           | **{dotted-circle}** No       | Returns merge requests that do not match the parameters supplied. Accepts: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `reviewer_id`, `reviewer_username`, `my_reaction_emoji`. |
| `order_by`                      | string         | **{dotted-circle}** No       | Returns requests ordered by `created_at`, `title` or `updated_at` fields. Default is `created_at`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/331625) in GitLab 14.8. |
| `reviewer_id`                   | integer        | **{dotted-circle}** No       | Returns merge requests which have the user as a [reviewer](../user/project/merge_requests/reviews/index.md) with the given user `id`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer. Mutually exclusive with `reviewer_username`.  |
| `reviewer_username`             | string         | **{dotted-circle}** No       | Returns merge requests which have the user as a [reviewer](../user/project/merge_requests/reviews/index.md) with the given `username`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer. Mutually exclusive with `reviewer_id`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49341) in GitLab 13.8. |
| `scope`                         | string         | **{dotted-circle}** No       | Returns merge requests for the given scope: `created_by_me`, `assigned_to_me`, or `all`. |
| `search`                        | string         | **{dotted-circle}** No       | Search merge requests against their `title` and `description`. |
| `sort`                          | string         | **{dotted-circle}** No       | Returns requests sorted in `asc` or `desc` order. Default is `desc`. |
| `source_branch`                 | string         | **{dotted-circle}** No       | Returns merge requests with the given source branch. |
| `state`                         | string         | **{dotted-circle}** No       | Returns all merge requests or just those that are `opened`, `closed`, `locked`, or `merged`. |
| `target_branch`                 | string         | **{dotted-circle}** No       | Returns merge requests with the given target branch. |
| `updated_after`                 | datetime       | **{dotted-circle}** No       | Returns merge requests updated on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `updated_before`                | datetime       | **{dotted-circle}** No       | Returns merge requests updated on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `view`                          | string         | **{dotted-circle}** No       | If `simple`, returns the `iid`, URL, title, description, and basic state of merge request. |
| `wip`                           | string         | **{dotted-circle}** No       | Filter merge requests against their `wip` status. `yes` to return *only* draft merge requests, `no` to return *non-draft* merge requests. |
| `with_labels_details`           | boolean        | **{dotted-circle}** No       | If `true`, response returns more details for each label in labels field: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. Default is `false`. |
| `with_merge_status_recheck`     | boolean        | **{dotted-circle}** No       | If `true`, this projection requests (but does not guarantee) that the `merge_status` field be recalculated asynchronously. Default is `false`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/31890) in GitLab 13.0. In GitLab 15.11 and later, enable the `restrict_merge_status_recheck` feature [flag](../administration/feature_flags.md) for this attribute to be ignored when requested by users without at least the Developer role. |

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 3,
    "title": "test1",
    "description": "fixed login page css paddings",
    "state": "merged",
    "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merge_user": {
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
    "detailed_merge_status": "not_open",
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

For important notes on response data, read [Merge requests list response notes](#merge-requests-list-response-notes).

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

`group_id` represents the ID of the group which contains the project where the merge request resides.

Supported attributes:

| Attribute                       | Type           | Required | Description |
| ------------------------------- | -------------- | -------- | ----------- |
| `id`                            | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `approved_by_ids` **(PREMIUM)** | integer array  | **{dotted-circle}** No       | Returns merge requests which have been approved by all the users with the given `id`, with a maximum of 5. `None` returns merge requests with no approvals. `Any` returns merge requests with an approval. |
| `approved_by_usernames` **(PREMIUM)** | string array  | **{dotted-circle}** No       | Returns merge requests which have been approved by all the users with the given `username`, with a maximum of 5. `None` returns merge requests with no approvals. `Any` returns merge requests with an approval. |
| `approver_ids` **(PREMIUM)**    | integer array  | **{dotted-circle}** No       | Returns merge requests which have specified all the users with the given `id`s as individual approvers. `None` returns merge requests without approvers. `Any` returns merge requests with an approver. |
| `approved`                      | string         | **{dotted-circle}** No       | Filters merge requests by their `approved` status. `yes` returns only approved merge requests. `no` returns only non-approved merge requests. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/3159) in GitLab 15.11. Available only when the feature flag `mr_approved_filter` is enabled. |
| `assignee_id`                   | integer        | **{dotted-circle}** No       | Returns merge requests assigned to the given user `id`. `None` returns unassigned merge requests. `Any` returns merge requests with an assignee. |
| `author_id`                     | integer        | **{dotted-circle}** No       | Returns merge requests created by the given user `id`. Mutually exclusive with `author_username`. |
| `author_username`               | string         | **{dotted-circle}** No       | Returns merge requests created by the given `username`. Mutually exclusive with `author_id`. |
| `created_after`                 | datetime       | **{dotted-circle}** No       | Returns merge requests created on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `created_before`                | datetime       | **{dotted-circle}** No       | Returns merge requests created on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `labels`                        | string         | **{dotted-circle}** No       | Returns merge requests matching a comma-separated list of labels. `None` lists all merge requests with no labels. `Any` lists all merge requests with at least one label. Predefined names are case-insensitive. |
| `milestone`                     | string         | **{dotted-circle}** No       | Returns merge requests for a specific milestone. `None` returns merge requests with no milestone. `Any` returns merge requests that have an assigned milestone. |
| `my_reaction_emoji`             | string         | **{dotted-circle}** No       | Returns merge requests reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction. |
| `non_archived`                  | boolean        | **{dotted-circle}** No       | Returns merge requests from non archived projects only. Default is `true`. |
| `not`                           | Hash           | **{dotted-circle}** No       | Returns merge requests that do not match the parameters supplied. Accepts: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `reviewer_id`, `reviewer_username`, `my_reaction_emoji`. |
| `order_by`                      | string         | **{dotted-circle}** No       | Returns merge requests ordered by `created_at`, `title` or `updated_at` fields. Default is `created_at`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/331625) in GitLab 14.8. |
| `reviewer_id`                   | integer        | **{dotted-circle}** No       | Returns merge requests which have the user as a [reviewer](../user/project/merge_requests/reviews/index.md) with the given user `id`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer. Mutually exclusive with `reviewer_username`. |
| `reviewer_username`             | string         | **{dotted-circle}** No       | Returns merge requests which have the user as a [reviewer](../user/project/merge_requests/reviews/index.md) with the given `username`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer. Mutually exclusive with `reviewer_id`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49341) in GitLab 13.8. |
| `scope`                         | string         | **{dotted-circle}** No       | Returns merge requests for the given scope: `created_by_me`, `assigned_to_me` or `all`. |
| `search`                        | string         | **{dotted-circle}** No       | Search merge requests against their `title` and `description`. |
| `source_branch`                 | string         | **{dotted-circle}** No       | Returns merge requests with the given source branch. |
| `sort`                          | string         | **{dotted-circle}** No       | Returns merge requests sorted in `asc` or `desc` order. Default is `desc`. |
| `state`                         | string         | **{dotted-circle}** No       | Returns all merge requests or just those that are `opened`, `closed`, `locked`, or `merged`. |
| `target_branch`                 | string         | **{dotted-circle}** No       | Returns merge requests with the given target branch. |
| `updated_after`                 | datetime       | **{dotted-circle}** No       | Returns merge requests updated on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `updated_before`                | datetime       | **{dotted-circle}** No       | Returns merge requests updated on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `view`                          | string         | **{dotted-circle}** No       | If `simple`, returns the `iid`, URL, title, description, and basic state of merge request. |
| `with_labels_details`           | boolean        | **{dotted-circle}** No       | If `true`, response returns more details for each label in labels field: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. Default is `false`. |
| `with_merge_status_recheck`     | boolean        | **{dotted-circle}** No       | If `true`, this projection requests (but does not guarantee) that the `merge_status` field be recalculated asynchronously. Default is `false`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/31890) in GitLab 13.0. In GitLab 15.11 and later, enable the `restrict_merge_status_recheck` feature [flag](../administration/feature_flags.md) for this attribute to be ignored when requested by users without at least the Developer role. |

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 3,
    "title": "test1",
    "description": "fixed login page css paddings",
    "state": "merged",
    "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merge_user": {
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
    "detailed_merge_status": "not_open",
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

For important notes on response data, read [Merge requests list response notes](#merge-requests-list-response-notes).

## Get single MR

Shows information about a single merge request.

**Note**: the `changes_count` value in the response is a string, not an
integer. When an merge request has too many changes to display and store,
it is capped at 1,000. In that case, the API returns the string
`"1000+"` for the changes count.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid
```

Supported attributes:

| Attribute                        | Type           | Required | Description |
|----------------------------------|----------------|----------|-------------|
| `id`                             | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid`              | integer        | **{check-circle}** Yes      | The internal ID of the merge request. |
| `include_diverged_commits_count` | boolean        | **{dotted-circle}** No       | If `true`, response includes the commits behind the target branch. |
| `include_rebase_in_progress`     | boolean        | **{dotted-circle}** No       | If `true`, response includes whether a rebase operation is in progress. |
| `render_html`                    | boolean        | **{dotted-circle}** No       | If `true`, response includes rendered HTML for title and description. |

### Response

| Attribute                        | Type | Description |
|----------------------------------|------|-------------|
| `approvals_before_merge`| integer |  **(PREMIUM)** Number of approvals required before this merge request can merge. To configure approval rules, see [Merge request approvals API](merge_request_approvals.md). [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) in GitLab 16.0. |
| `assignee` | object | First assignee of the merge request. |
| `assignees` | array | Assignees of the merge request. |
| `author` | object | User who created this merge request. |
| `blocking_discussions_resolved` | boolean | Indicates if all discussions are resolved only if all are required before merge request can be merged. |
| `changes_count` | string | Number of changes made on the merge request. Empty when the merge request is created, and populates asynchronously. See [Empty API Fields for new merge requests](#empty-api-fields-for-new-merge-requests).|
| `closed_at` | datetime | Timestamp of when the merge request was closed. |
| `closed_by` | object | User who closed this merge request. |
| `created_at` | datetime | Timestamp of when the merge request was created. |
| `description` | string | Description of the merge request. Contains Markdown rendered as HTML for caching. |
| `detailed_merge_status` | string | Detailed merge status of the merge request. Read [merge status](#merge-status) for a list of potential values. |
| `diff_refs` | object | References of the base SHA, the head SHA, and the start SHA for this merge request. Corresponds to the latest diff version of the merge request. Empty when the merge request is created, and populates asynchronously. See [Empty API fields for new merge requests](#empty-api-fields-for-new-merge-requests). |
| `discussion_locked` | boolean | Indicates if comments on the merge request are locked to members only. |
| `downvotes` | integer | Number of downvotes for the merge request. |
| `draft` | boolean | Indicates if the merge request is a draft. |
| `first_contribution` | boolean | Indicates if the merge request is the first contribution of the author. |
| `first_deployed_to_production_at` | datetime | Timestamp of when the first deployment finished. |
| `force_remove_source_branch` | boolean | Indicates if the project settings will lead to source branch deletion after merge. |
| `has_conflicts` | boolean | Indicates if merge request has conflicts and cannot be merged. Dependent on the `merge_status` property. Returns `false` unless `merge_status` is `cannot_be_merged`. |
| `head_pipeline` | object | Pipeline running on the branch HEAD of the merge request. Contains more complete information than `pipeline` and should be used instead of it. |
| `id` | integer | ID of the merge request. |
| `iid` | integer | Internal ID of the merge request. |
| `labels` | array | Labels of the merge request. |
| `latest_build_finished_at` | datetime | Timestamp of when the latest build for the merge request finished. |
| `latest_build_started_at` | datetime | Timestamp of when the latest build for the merge request started. |
| `merge_commit_sha` | string | SHA of the merge request commit. Returns `null` until merged. |
| `merge_error` | string | Error message shown when a merge has failed. To check mergeability, use `detailed_merge_status` instead  |
| `merge_user` | object | The user who merged this merge request, the user who set it to merge when pipeline succeeds, or `null`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/349031) in GitLab 14.7. |
| `merge_status` | string | Status of the merge request. Can be `unchecked`, `checking`, `can_be_merged`, `cannot_be_merged`, or `cannot_be_merged_recheck`. Affects the `has_conflicts` property. For important notes on response data, read [Single merge request response notes](#single-merge-request-response-notes). [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204) in GitLab 15.6. Use `detailed_merge_status` instead. |
| `merge_when_pipeline_succeeds` | boolean | Indicates if the merge has been set to be merged when its pipeline succeeds. |
| `merged_at` | datetime | Timestamp of when the merge request was merged. |
| `merged_by` | object | User who merged this merge request or set it to merge when pipeline succeeds. [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/350534) in GitLab 14.7, and scheduled for removal in [API version 5](https://gitlab.com/groups/gitlab-org/-/epics/8115). Use `merge_user` instead. |
| `milestone` | object | Milestone of the merge request. |
| `pipeline` | object | Pipeline running on the branch HEAD of the merge request. Consider using `head_pipeline` instead, as it contains more information. |
| `project_id` | integer | ID of the merge request project. |
| `reference` | string | Internal reference of the merge request. Returned in shortened format by default. [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20354) in GitLab 12.7, and scheduled for removal in [API version 5](https://gitlab.com/groups/gitlab-org/-/epics/8115). Use `references` instead. |
| `references` | object | Internal references of the merge request. Includes `short`, `relative`, and `full` references. `references.relative` is relative to the merge request's group or project. When fetched from the merge request's project, `relative` and `short` formats are identical. When requested across groups or projects, `relative` and `full` formats are identical.|
| `reviewers` | array | Reviewers of the merge request. |
| `sha` | string | Diff head SHA of the merge request. |
| `should_remove_source_branch` | boolean | Indicates if the source branch of the merge request will be deleted after merge. |
| `source_branch` | string | Source branch of the merge request. |
| `source_project_id` | integer | ID of the merge request source project. |
| `squash` | boolean | Indicates if squash on merge is enabled. |
| `squash_commit_sha` | string | SHA of the squash commit. Empty until merged. |
| `state` | string | State of the merge request. Can be `opened`, `closed`, `merged` or `locked`. |
| `subscribed` | boolean | Indicates if the currently authenticated user is subscribed to this merge request. |
| `target_branch` | string | Target branch of the merge request. |
| `target_project_id` | integer | ID of the merge request target project. |
| `task_completion_status` | object | Completion status of tasks. |
| `title` | string | Title of the merge request. |
| `updated_at` | datetime | Timestamp of when the merge request was updated. |
| `upvotes` | integer | Number of upvotes for the merge request. |
| `user` | object | Permissions of the user requested for the merge request. |
| `user_notes_count` | integer | User notes count of the merge request. |
| `web_url` | string | Web URL of the merge request. |
| `work_in_progress` | boolean | Deprecated: Use `draft` instead. Indicates if the merge request is a draft. |

```json
{
  "id": 155016530,
  "iid": 133,
  "project_id": 15513260,
  "title": "Manual job rules",
  "description": "",
  "state": "opened",
  "created_at": "2022-05-13T07:26:38.402Z",
  "updated_at": "2022-05-14T03:38:31.354Z",
  "merged_by": null, // Deprecated and will be removed in API v5. Use `merge_user` instead.
  "merge_user": null,
  "merged_at": null,
  "closed_by": null,
  "closed_at": null,
  "target_branch": "master",
  "source_branch": "manual-job-rules",
  "user_notes_count": 0,
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 4155490,
    "username": "marcel.amirault",
    "name": "Marcel Amirault",
    "state": "active",
    "avatar_url": "https://gitlab.com/uploads/-/system/user/avatar/4155490/avatar.png",
    "web_url": "https://gitlab.com/marcel.amirault"
  },
  "assignees": [],
  "assignee": null,
  "reviewers": [],
  "source_project_id": 15513260,
  "target_project_id": 15513260,
  "labels": [],
  "draft": false,
  "work_in_progress": false,
  "milestone": null,
  "merge_when_pipeline_succeeds": false,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "can_be_merged",
  "sha": "e82eb4a098e32c796079ca3915e07487fc4db24c",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "discussion_locked": null,
  "should_remove_source_branch": null,
  "force_remove_source_branch": true,
  "reference": "!133", // Deprecated. Use `references` instead.
  "references": {
    "short": "!133",
    "relative": "!133",
    "full": "marcel.amirault/test-project!133"
  },
  "web_url": "https://gitlab.com/marcel.amirault/test-project/-/merge_requests/133",
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "task_completion_status": {
    "count": 0,
    "completed_count": 0
  },
  "has_conflicts": false,
  "blocking_discussions_resolved": true,
  "approvals_before_merge": null, // deprecated, use [Merge request approvals API](merge_request_approvals.md)
  "subscribed": true,
  "changes_count": "1",
  "latest_build_started_at": "2022-05-13T09:46:50.032Z",
  "latest_build_finished_at": null,
  "first_deployed_to_production_at": null,
  "pipeline": { // Use `head_pipeline` instead.
    "id": 538317940,
    "iid": 1877,
    "project_id": 15513260,
    "sha": "1604b0c46c395822e4e9478777f8e54ac99fe5b9",
    "ref": "refs/merge-requests/133/merge",
    "status": "failed",
    "source": "merge_request_event",
    "created_at": "2022-05-13T09:46:39.560Z",
    "updated_at": "2022-05-13T09:47:20.706Z",
    "web_url": "https://gitlab.com/marcel.amirault/test-project/-/pipelines/538317940"
  },
  "head_pipeline": {
    "id": 538317940,
    "iid": 1877,
    "project_id": 15513260,
    "sha": "1604b0c46c395822e4e9478777f8e54ac99fe5b9",
    "ref": "refs/merge-requests/133/merge",
    "status": "failed",
    "source": "merge_request_event",
    "created_at": "2022-05-13T09:46:39.560Z",
    "updated_at": "2022-05-13T09:47:20.706Z",
    "web_url": "https://gitlab.com/marcel.amirault/test-project/-/pipelines/538317940",
    "before_sha": "1604b0c46c395822e4e9478777f8e54ac99fe5b9",
    "tag": false,
    "yaml_errors": null,
    "user": {
      "id": 4155490,
      "username": "marcel.amirault",
      "name": "Marcel Amirault",
      "state": "active",
      "avatar_url": "https://gitlab.com/uploads/-/system/user/avatar/4155490/avatar.png",
      "web_url": "https://gitlab.com/marcel.amirault"
    },
    "started_at": "2022-05-13T09:46:50.032Z",
    "finished_at": "2022-05-13T09:47:20.697Z",
    "committed_at": null,
    "duration": 30,
    "queued_duration": 10,
    "coverage": null,
    "detailed_status": {
      "icon": "status_failed",
      "text": "failed",
      "label": "failed",
      "group": "failed",
      "tooltip": "failed",
      "has_details": true,
      "details_path": "/marcel.amirault/test-project/-/pipelines/538317940",
      "illustration": null,
      "favicon": "/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png"
    }
  },
  "diff_refs": {
    "base_sha": "1162f719d711319a2efb2a35566f3bfdadee8bab",
    "head_sha": "e82eb4a098e32c796079ca3915e07487fc4db24c",
    "start_sha": "1162f719d711319a2efb2a35566f3bfdadee8bab"
  },
  "merge_error": null,
  "first_contribution": false,
  "user": {
    "can_merge": true
  },
  "approvals_before_merge": { // Available for GitLab Premium and Ultimate tiers only
    "id": 1,
    "title": "test1",
    "approvals_before_merge": null
  },
}
```

### Single merge request response notes

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/29984) in GitLab 12.8, the mergeability (`merge_status`)
  of each merge request is checked asynchronously when a request is made to this endpoint. Poll this API endpoint
  to get updated status. This affects the `has_conflicts` property as it is dependent on the `merge_status`. It returns
  `false` unless `merge_status` is `cannot_be_merged`.

### Merge status

> - The `merge_status` field was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204) in GitLab 15.6.
> - The `detailed_merge_status` field was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101724) in GitLab 15.6.

Use `detailed_merge_status` instead of `merge_status` to account for all potential statuses.

- The `detailed_merge_status` field can contain one of the following values related to the merge request:
  - `blocked_status`: Blocked by another merge request.
  - `broken_status`: Can't merge into the target branch due to a potential conflict.
  - `checking`: Git is testing if a valid merge is possible.
  - `unchecked`: Git has not yet tested if a valid merge is possible.
  - `ci_must_pass`: A CI/CD pipeline must succeed before merge.
  - `ci_still_running`: A CI/CD pipeline is still running.
  - `discussions_not_resolved`: All discussions must be resolved before merge.
  - `draft_status`: Can't merge because the merge request is a draft.
  - `external_status_checks`: All status checks must pass before merge.
  - `mergeable`: The branch can merge cleanly into the target branch.
  - `not_approved`: Approval is required before merge.
  - `not_open`: The merge request must be open before merge.
  - `policies_denied`: The merge request contains denied policies.

## Get single merge request participants

Get a list of merge request participants.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/participants
```

Supported attributes:

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer        | **{check-circle}** Yes      | The internal ID of the merge request. |

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

## Get single merge request reviewers

Get a list of merge request reviewers.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/reviewers
```

Supported attributes:

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | **{check-circle}** Yes   | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer        | **{check-circle}** Yes      | The internal ID of the merge request. |

```json
[
  {
    "user": {
      "id": 1,
      "name": "John Doe1",
      "username": "user1",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
      "web_url": "http://localhost/user1"
    },
    "state": "unreviewed",
    "created_at": "2022-07-27T17:03:27.684Z"
  },
  {
    "user": {
      "id": 2,
      "name": "John Doe2",
      "username": "user2",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80&d=identicon",
      "web_url": "http://localhost/user2"
    },
    "state": "reviewed",
    "created_at": "2022-07-27T17:03:27.684Z"
  }
]
```

## Get single merge request commits

Get a list of merge request commits.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/commits
```

Supported attributes:

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer        | **{check-circle}** Yes      | The internal ID of the merge request. |

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

## Get single merge request changes

WARNING:
This endpoint was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/322117) in GitLab 15.7
and will be removed in API v5. Use the [List merge request diffs](#list-merge-request-diffs) endpoint instead.

Shows information about the merge request including its files and changes.

[Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/46190) in GitLab 13.6,
diffs associated with the set of changes have the same size limitations applied as other diffs
returned by the API or viewed via the UI. When these limits impact the results, the `overflow`
field contains a value of `true`. Diff data without these limits applied can be retrieved by
adding the `access_raw_diffs` parameter, accessing diffs not from the database but from Gitaly directly.
This approach is generally slower and more resource-intensive, but isn't subject to size limits
placed on database-backed diffs. [Limits inherent to Gitaly](../development/merge_request_concepts/diffs/index.md#diff-limits)
still apply.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/changes
```

Supported attributes:

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer        | **{check-circle}** Yes      | The internal ID of the merge request. |
| `access_raw_diffs`  | boolean        | **{dotted-circle}** No       | Retrieve change diffs via Gitaly. |

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
  "detailed_merge_status": "can_be_merged",
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

## List merge request diffs

List diffs of the files changed in a merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/diffs
```

Supported attributes:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer | **{check-circle}** Yes | The internal ID of the merge request. |
| `page` | integer | **{dotted-circle}** no | The page of results to return. Defaults to 1. |
| `per_page` | integer | **{dotted-circle}** no | The number of results per page. Defaults to 20. |

If successful, returns [`200 OK`](rest/index.md#status-codes) and the
following response attributes:

| Attribute | Type | Description |
|:----------|:-----|:------------|
| `old_path` | string | Old path of the file. |
| `new_path` | string | New path of the file. |
| `a_mode` | string | Old file mode of the file. |
| `b_mode` | string | New file mode of the file. |
| `diff` | string | Diff representation of the changes made on the file. |
| `new_file` | boolean | Indicates if the file has just been added. |
| `renamed_file` | boolean | Indicates if the file has been renamed. |
| `deleted_file` | boolean | Indicates if the file has been removed. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/diffs?page=1&per_page=2"
```

Example response:

```json
[
  {
    "old_path": "README",
    "new_path": "README",
    "a_mode": "100644",
    "b_mode": "100644",
    "diff": "--- a/README\ +++ b/README\ @@ -1 +1 @@\ -Title\ +README",
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false
  },
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
]
```

## List merge request pipelines

Get a list of merge request pipelines. The pagination parameters `page` and
`per_page` can be used to restrict the list of merge request pipelines.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/pipelines
```

Supported attributes:

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer        | **{check-circle}** Yes      | The internal ID of the merge request. |

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

## Create merge request pipeline

Create a new [pipeline for a merge request](../ci/pipelines/merge_request_pipelines.md).
A pipeline created via this endpoint doesn't run a regular branch/tag pipeline.
It requires `.gitlab-ci.yml` to be configured with `only: [merge_requests]` to create jobs.

The new pipeline can be:

- A detached merge request pipeline.
- A [merged results pipeline](../ci/pipelines/merged_results_pipelines.md)
  if the [project setting is enabled](../ci/pipelines/merged_results_pipelines.md#enable-merged-results-pipelines).

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/pipelines
```

Supported attributes:

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer        | **{check-circle}** Yes      | The internal ID of the merge request. |

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

| Attribute                  | Type    | Required | Description |
| ---------                  | ----    | -------- | ----------- |
| `id`                       | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user |
| `source_branch`            | string  | **{check-circle}** Yes      | The source branch. |
| `target_branch`            | string  | **{check-circle}** Yes      | The target branch. |
| `title`                    | string  | **{check-circle}** Yes      | Title of MR. |
| `allow_collaboration`      | boolean | **{dotted-circle}** No       | Allow commits from members who can merge to the target branch. |
| `approvals_before_merge` **(PREMIUM)**                      | integer | **{dotted-circle}** No | Number of approvals required before this can be merged (see below). To configure approval rules, see [Merge request approvals API](merge_request_approvals.md). [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) in GitLab 16.0. |
| `allow_maintainer_to_push` | boolean | **{dotted-circle}** No       | Alias of `allow_collaboration`. |
| `assignee_id`              | integer | **{dotted-circle}** No       | Assignee user ID. |
| `assignee_ids`             | integer array | **{dotted-circle}** No | The ID of the users to assign the merge request to. Set to `0` or provide an empty value to unassign all assignees. |
| `description`              | string  | **{dotted-circle}** No       | Description of the merge request. Limited to 1,048,576 characters. |
| `labels`                   | string  | **{dotted-circle}** No       | Labels for the merge request, as a comma-separated list. |
| `milestone_id`             | integer | **{dotted-circle}** No       | The global ID of a milestone. |
| `remove_source_branch`     | boolean | **{dotted-circle}** No       | Flag indicating if a merge request should remove the source branch when merging. |
| `reviewer_ids`             | integer array | **{dotted-circle}** No | The ID of the users added as a reviewer to the merge request. If set to `0` or left empty, no reviewers are added. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49341) in GitLab 13.8. |
| `squash`                   | boolean | no       | Indicates if the merge request is set to be squashed when merged. [Project settings](../user/project/merge_requests/squash_and_merge.md#configure-squash-options-for-a-project) may override this value. Use `squash_on_merge` instead to take project squash options into account. |
| `squash_on_merge`          | boolean | no       | Indicates if the merge request will be squashed when merged. |
| `target_project_id`        | integer | **{dotted-circle}** No       | Numeric ID of the target project. |

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
  "detailed_merge_status": "not_open",
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
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
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

For important notes on response data, read [Single merge request response notes](#single-merge-request-response-notes).

## Update MR

Updates an existing merge request. You can change the target branch, title, or even close the MR.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid
```

| Attribute                  | Type    | Required | Description |
| ---------                  | ----    | -------- | ----------- |
| `id`                       | integer or string | **{check-circle}** Yes  | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid`        | integer | **{check-circle}** Yes      | The ID of a merge request. |
| `add_labels`               | string  | **{dotted-circle}** No       | Comma-separated label names to add to a merge request. |
| `allow_collaboration`      | boolean | **{dotted-circle}** No       | Allow commits from members who can merge to the target branch. |
| `allow_maintainer_to_push` | boolean | **{dotted-circle}** No       | Alias of `allow_collaboration`. |
| `assignee_id`              | integer | **{dotted-circle}** No       | The ID of the user to assign the merge request to. Set to `0` or provide an empty value to unassign all assignees. |
| `assignee_ids`             | integer array | **{dotted-circle}** No | The ID of the users to assign the merge request to. Set to `0` or provide an empty value to unassign all assignees. |
| `description`              | string  | **{dotted-circle}** No       | Description of the merge request. Limited to 1,048,576 characters. |
| `discussion_locked`        | boolean | **{dotted-circle}** No       | Flag indicating if the merge request's discussion is locked. If the discussion is locked only project members can add, edit or resolve comments. |
| `labels`                   | string  | **{dotted-circle}** No       | Comma-separated label names for a merge request. Set to an empty string to unassign all labels.                    |
| `milestone_id`             | integer | **{dotted-circle}** No       | The global ID of a milestone to assign the merge request to. Set to `0` or provide an empty value to unassign a milestone.|
| `remove_labels`            | string  | **{dotted-circle}** No       | Comma-separated label names to remove from a merge request. |
| `remove_source_branch`     | boolean | **{dotted-circle}** No       | Flag indicating if a merge request should remove the source branch when merging. |
| `reviewer_ids`             | integer array | **{dotted-circle}** No | The ID of the users set as a reviewer to the merge request. Set the value to `0` or provide an empty value to unset all reviewers. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49341) in GitLab 13.8. |
| `squash`                   | boolean | no       | Indicates if the merge request is set to be squashed when merged. [Project settings](../user/project/merge_requests/squash_and_merge.md#configure-squash-options-for-a-project) may override this value. Use `squash_on_merge` instead to take project squash options into account. |
| `squash_on_merge`          | boolean | no       | Indicates if the merge request will be squashed when merged. |
| `state_event`              | string  | **{dotted-circle}** No       | New state (close/reopen). |
| `target_branch`            | string  | **{dotted-circle}** No       | The target branch. |
| `title`                    | string  | **{dotted-circle}** No       | Title of MR. |

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
  "detailed_merge_status": "not_open",
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
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
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

For important notes on response data, read [Single merge request response notes](#single-merge-request-response-notes).

## Delete a merge request

Only for administrators and project owners. Deletes the merge request in question.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid
```

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer        | **{check-circle}** Yes      | The internal ID of the merge request. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/4/merge_requests/85"
```

## Merge a merge request

Accept and merge changes submitted with merge request using this API.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/merge
```

Supported attributes:

| Attribute                      | Type           | Required | Description |
|--------------------------------|----------------|----------|-------------|
| `id`                           | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid`            | integer        | **{check-circle}** Yes      | The internal ID of the merge request. |
| `merge_commit_message`         | string         | **{dotted-circle}** No       | Custom merge commit message. |
| `merge_when_pipeline_succeeds` | boolean        | **{dotted-circle}** No       | If `true`, the merge request is merged when the pipeline succeeds. |
| `sha`                          | string         | **{dotted-circle}** No       | If present, then this SHA must match the HEAD of the source branch, otherwise the merge fails. |
| `should_remove_source_branch`  | boolean        | **{dotted-circle}** No       | If `true`, removes the source branch. |
| `squash_commit_message`        | string         | **{dotted-circle}** No       | Custom squash commit message. |
| `squash`                       | boolean        | **{dotted-circle}** No       | If `true`, the commits are squashed into a single commit on merge. |

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
  "detailed_merge_status": "not_open",
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
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
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

This API returns specific HTTP status codes on failure:

| HTTP Status | Message | Reason |
|:------------|---------|--------|
| `401` | `Unauthorized` | This user does not have permission to accept this merge request. |
| `405` | `Method Not Allowed` | The merge request is not able to be merged. |
| `409` | `SHA does not match HEAD of source branch` | The provided `sha` parameter does not match the HEAD of the source. |
| `422` | `Branch cannot be merged` | The merge request failed to merge. |

For additional important notes on response data, read [Single merge request response notes](#single-merge-request-response-notes).

## Merge to default merge ref path

Merge the changes between the merge request source and target branches into `refs/merge-requests/:iid/merge`
ref, of the target project repository, if possible. This ref has the state the target branch would have if
a regular merge action was taken.

This action isn't a regular merge action, because it doesn't change the merge request target branch state in any manner.

This ref (`refs/merge-requests/:iid/merge`) isn't necessarily overwritten when submitting
requests to this API, though it makes sure the ref has the latest possible state.

If the merge request has conflicts, is empty or already merged, you receive a `400` and a descriptive error message.

It returns the HEAD commit of `refs/merge-requests/:iid/merge` in the response body in case of `200`.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/merge_ref
```

Supported attributes:

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer        | **{check-circle}** Yes      | The internal ID of the merge request. |

```json
{
  "commit_id": "854a3a7a17acbcc0bbbea170986df1eb60435f34"
}
```

## Cancel Merge When Pipeline Succeeds

This API returns specific HTTP status codes on failure:

| HTTP Status | Message              | Reason                                                                |
|-------------|----------------------|-----------------------------------------------------------------------|
| `401`       | `Unauthorized`       | This user does not have permission to cancel this merge request.      |
| `405`       | `Method Not Allowed` | The merge request is already merged or closed.                        |
| `406`       | `Not Acceptable`     | The merge request is not set to be merged when the pipeline succeeds. |

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/cancel_merge_when_pipeline_succeeds
```

Supported attributes:

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer        | **{check-circle}** Yes      | The internal ID of the merge request. |

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
  "detailed_merge_status": "not_open",
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
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
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

For important notes on response data, read [Single merge request response notes](#single-merge-request-response-notes).

## Rebase a merge request

Automatically rebase the `source_branch` of the merge request against its
`target_branch`.

If you don't have permissions to push to the merge request's source branch -
you receive a `403 Forbidden` response.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/rebase
```

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer        | **{check-circle}** Yes      | The internal ID of the merge request. |
| `skip_ci`           | boolean        | **{dotted-circle}** No       | Set to `true` to skip creating a CI pipeline. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/76/merge_requests/1/rebase"
```

This request is asynchronous. The API returns a `HTTP 202 Accepted` response
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

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer        | **{check-circle}** Yes      | The internal ID of the merge request. |

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

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer        | **{check-circle}** Yes      | The internal ID of the merge request. |

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
  "detailed_merge_status": "not_open",
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
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
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

For important notes on response data, read [Single merge request response notes](#single-merge-request-response-notes).

## Unsubscribe from a merge request

Unsubscribes the authenticated user from a merge request to not receive
notifications from that merge request. If the user is
not subscribed to the merge request, the status code `HTTP 304 Not Modified` is returned.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/unsubscribe
```

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer        | **{check-circle}** Yes      | The internal ID of the merge request. |

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
  "detailed_merge_status": "not_open",
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
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
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

For important notes on response data, read [Single merge request response notes](#single-merge-request-response-notes).

## Create a to-do item

Manually creates a to-do item for the current user on a merge request.
If there already exists a to-do item for the user on that merge request,
status code `HTTP 304 Not Modified` is returned.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/todo
```

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer        | **{check-circle}** Yes      | The internal ID of the merge request. |

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
    "detailed_merge_status": "not_open",
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

## Get merge request diff versions

Get a list of merge request diff versions. For an explanation of the SHAs in the response,
read [SHAs in the API response](#shas-in-the-api-response).

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/versions
```

| Attribute           | Type    | Required | Description                           |
|---------------------|---------|----------|---------------------------------------|
| `id`                | String  | **{check-circle}** Yes      | The ID of the project.                |
| `merge_request_iid` | integer | **{check-circle}** Yes      | The internal ID of the merge request. |

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

| SHA field          | Purpose                                                                             |
|--------------------|-------------------------------------------------------------------------------------|
| `base_commit_sha`  | The merge-base commit SHA between the source branch and the target branches.        |
| `head_commit_sha`  | The HEAD commit of the source branch.                                               |
| `start_commit_sha` | The HEAD commit SHA of the target branch when this version of the diff was created. |

## Get a single merge request diff version

Get a single merge request diff version. For an explanation of the SHAs in the response,
read [SHAs in the API response](#shas-in-the-api-response).

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/versions/:version_id
```

| Attribute           | Type    | Required | Description                               |
|---------------------|---------|----------|-------------------------------------------|
| `id`                | String  | **{check-circle}** Yes      | The ID of the project.                    |
| `merge_request_iid` | integer | **{check-circle}** Yes      | The internal ID of the merge request.     |
| `version_id`        | integer | **{check-circle}** Yes      | The ID of the merge request diff version. |

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

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer        | **{check-circle}** Yes      | The internal ID of the merge request. |
| `duration`          | string         | **{check-circle}** Yes      | The duration in human format, such as `3h30m`. |

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

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer        | **{check-circle}** Yes      | The internal ID of a project's merge request. |

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

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer        | **{check-circle}** Yes      | The internal ID of the merge request. |
| `duration`          | string         | **{check-circle}** Yes      | The duration in human format, such as `3h30m` |
| `summary`           | string         | **{dotted-circle}** No       | A summary of how the time was spent. |

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

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer        | **{check-circle}** Yes      | The internal ID of a project's merge request. |

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

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | **{check-circle}** Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `merge_request_iid` | integer        | **{check-circle}** Yes      | The internal ID of the merge request. |

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

For approvals, see [Merge request approvals](merge_request_approvals.md)

## List merge request state events

To track which state was set, who did it, and when it happened, check out
[Resource state events API](resource_state_events.md#merge-requests).

## Troubleshooting

### Empty API fields for new merge requests

When a merge request is created, the `diff_refs` and `changes_count` fields are
initially empty. These fields are populated asynchronously after the
merge request is created. For more information, see the issue
[Some merge request API fields (`diff_refs`, `changes_count`) empty after MR is created](https://gitlab.com/gitlab-org/gitlab/-/issues/386562),
and the [related discussion](https://forum.gitlab.com/t/diff-refs-empty-after-mr-is-created/78975)
in the GitLab forums.
