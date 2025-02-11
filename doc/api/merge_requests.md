---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Documentation for the REST API for merge requests in GitLab."
title: Merge requests API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - `reference` [deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20354) in GitLab 12.7.
> - `merged_by` [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/350534) in GitLab 14.7.
> - `merge_status` [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204) in favor of `detailed_merge_status` in GitLab 15.6.
> - `with_merge_status_recheck` [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115948) in GitLab 15.11 [with a flag](../administration/feature_flags.md) named `restrict_merge_status_recheck` to be ignored for requests from users insufficient permissions. Disabled by default.
> - `approvals_before_merge` [deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119503) in GitLab 16.0.
> - `prepared_at` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122001) in GitLab 16.1.
> - `merge_after` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165092) in GitLab 17.5.

All API calls to non-public information require authentication.

## Removals in API v5

The `approvals_before_merge` attribute is deprecated, and [is scheduled for removal](rest/deprecations.md)
in API v5 in favor of the [Merge request approvals API](merge_request_approvals.md).

## List merge requests

Get all merge requests the authenticated user has access to. By
default it returns only merge requests created by the current user. To
get all merge requests, use parameter `scope=all`.

Use the `state` parameter to get only merge requests with a
given state (`opened`, `closed`, `locked`, or `merged`) or all states (`all`).
Searching by `locked` generally returns no results
as that state is short-lived and transitional. Use the pagination parameters `page` and
`per_page` to restrict the list of merge requests.

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

| Attribute                   | Type          | Required | Description |
|-----------------------------|---------------|----------|-------------|
| `approved_by_ids`               | integer array  | No       | Returns the merge requests approved by all the users with the given `id`, up to 5 users. `None` returns merge requests with no approvals. `Any` returns merge requests with an approval. Premium and Ultimate only.                                                                                                                                        |
| `approver_ids`                  | integer array  | No       | Returns merge requests which have specified all the users with the given `id` as individual approvers. `None` returns merge requests without approvers. `Any` returns merge requests with an approver. Premium and Ultimate only.                                                                                                                          |
| `approved`                      | string         | No       | Filters merge requests by their `approved` status. `yes` returns only approved merge requests. `no` returns only non-approved merge requests. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/3159) in GitLab 15.11 with the flag `mr_approved_filter`. Disabled by default.                                                                    |
| `assignee_id`                   | integer        | No       | Returns merge requests assigned to the given user `id`. `None` returns unassigned merge requests. `Any` returns merge requests with an assignee.                                                                                                                                                                                                           |
| `author_id`                     | integer        | No       | Returns merge requests created by the given user `id`. Mutually exclusive with `author_username`. Combine with `scope=all` or `scope=assigned_to_me`.                                                                                                                                                                                                      |
| `author_username`               | string         | No       | Returns merge requests created by the given `username`. Mutually exclusive with `author_id`.                                                                                                                                                                                                                                                               |
| `created_after`                 | datetime       | No       | Returns merge requests created on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`).                                                                                                                                                                                                                                           |
| `created_before`                | datetime       | No       | Returns merge requests created on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`).                                                                                                                                                                                                                                          |
| `deployed_after`                | datetime       | No       | Returns merge requests deployed after the given date/time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`).                                                                                                                                                                                                                                           |
| `deployed_before`               | datetime       | No       | Returns merge requests deployed before the given date/time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`).                                                                                                                                                                                                                                          |
| `environment`                   | string         | No       | Returns merge requests deployed to the given environment.                                                                                                                                                                                                                                                                                                  |
| `in`                            | string         | No       | Change the scope of the `search` attribute. `title`, `description`, or a string joining them with comma. Default is `title,description`.                                                                                                                                                                                                                   |
| `labels`                        | string         | No       | Returns merge requests matching a comma-separated list of labels. `None` lists all merge requests with no labels. `Any` lists all merge requests with at least one label. Predefined names are case-insensitive.                                                                                                                                           |
| `merge_user_id`                 | integer        | No       | Returns the merge requests merged by the user with the given user `id`. Mutually exclusive with `merge_user_username`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002) in GitLab 17.0.                                                                                                                                          |
| `merge_user_username`           | string         | No       | Returns the merge requests merged by the user with the given `username`. Mutually exclusive with `merge_user_id`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002) in GitLab 17.0.                                                                                                                                               |
| `milestone`                     | string         | No       | Returns merge requests for a specific milestone. `None` returns merge requests with no milestone. `Any` returns merge requests that have an assigned milestone.                                                                                                                                                                                            |
| `my_reaction_emoji`             | string         | No       | Returns merge requests reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction.                                                                                                                                                                               |
| `not`                           | Hash           | No       | Returns merge requests that do not match the parameters supplied. Accepts: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `reviewer_id`, `reviewer_username`, `my_reaction_emoji`.                                                                                                                             |
| `order_by`                  | string        | No       | Returns requests ordered by `created_at`, `title`, `merged_at` ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147052) in GitLab 17.2), or `updated_at` fields. Default is `created_at`. |
| `reviewer_id`                   | integer        | No       | Returns merge requests which have the user as a [reviewer](../user/project/merge_requests/reviews/_index.md) with the given user `id`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer. Mutually exclusive with `reviewer_username`.                                                                        |
| `reviewer_username`             | string         | No       | Returns merge requests which have the user as a [reviewer](../user/project/merge_requests/reviews/_index.md) with the given `username`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer. Mutually exclusive with `reviewer_id`.                                                                             |
| `scope`                         | string         | No       | Returns merge requests for the given scope: `created_by_me`, `assigned_to_me` or `all`. Defaults to `created_by_me`.                                                                                                                                                                                                                                       |
| `search`                        | string         | No       | Search merge requests against their `title` and `description`.                                                                                                                                                                                                                                                                                             |
| `sort`                          | string         | No       | Returns requests sorted in `asc` or `desc` order. Default is `desc`.                                                                                                                                                                                                                                                                                       |
| `source_branch`                 | string         | No       | Returns merge requests with the given source branch.                                                                                                                                                                                                                                                                                                       |
| `state`                         | string         | No       | Returns all merge requests or just those that are `opened`, `closed`, `locked`, or `merged`.                                                                                                                                                                                                                                                               |
| `target_branch`                 | string         | No       | Returns merge requests with the given target branch.                                                                                                                                                                                                                                                                                                       |
| `updated_after`                 | datetime       | No       | Returns merge requests updated on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`).                                                                                                                                                                                                                                           |
| `updated_before`                | datetime       | No       | Returns merge requests updated on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`).                                                                                                                                                                                                                                          |
| `view`                          | string         | No       | If `simple`, returns the `iid`, URL, title, description, and basic state of merge request.                                                                                                                                                                                                                                                                 |
| `with_labels_details`           | boolean        | No       | If `true`, response returns more details for each label in labels field: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. Default is `false`.                                                                                                                                                                                        |
| `with_merge_status_recheck`     | boolean        | No       | If `true`, this projection requests (but does not guarantee) an asynchronous recalculation of the `merge_status` field. Default is `false`. In GitLab 15.11 and later, enable the `restrict_merge_status_recheck` feature [flag](../administration/feature_flags.md) to ignore this attribute when requested by users without at least the Developer role. |
| `wip`                           | string         | No       | Filter merge requests against their `wip` status. Use `yes` to return *only* draft merge requests, `no` to return *non-draft* merge requests.                                                                                                                                                                                                              |

Example response:

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 3,
    "title": "test1",
    "description": "fixed login page css paddings",
    "state": "merged",
    "imported": false,
    "imported_from": "none",
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
    "merge_after": "2018-09-07T11:16:00.000Z",
    "prepared_at": "2018-09-04T11:16:17.520Z",
    "closed_by": null,
    "closed_at": null,
    "created_at": "2017-04-29T08:46:00Z",
    "updated_at": "2017-04-29T08:46:00Z",
    "target_branch": "main",
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

- Listing merge requests might
  not proactively update `merge_status` (which also affects the `has_conflicts`), as this can be an expensive operation.
  If you need the value of these fields from this endpoint, set the `with_merge_status_recheck` parameter to
  `true` in the query.
- For notes on merge request object fields, see [Single merge request response notes](#single-merge-request-response-notes).

## List project merge requests

Get all merge requests for this project.

```plaintext
GET /projects/:id/merge_requests
GET /projects/:id/merge_requests?state=opened
GET /projects/:id/merge_requests?state=all
GET /projects/:id/merge_requests?iids[]=42&iids[]=43
GET /projects/:id/merge_requests?milestone=release
GET /projects/:id/merge_requests?labels=bug,reproduced
GET /projects/:id/merge_requests?my_reaction_emoji=star
```

Supported attributes:

| Attribute                       | Type           | Required | Description |
| ------------------------------- | -------------- | -------- | ----------- |
| `id`                            | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `approved_by_ids`               | integer array  | No       | Returns merge requests approved by all the users with the given `id`, up to 5 users. `None` returns merge requests with no approvals. `Any` returns merge requests with an approval. Premium and Ultimate only. |
| `approver_ids`                  | integer array  | No       | Returns merge requests which have specified all the users with the given `id` as individual approvers. `None` returns merge requests without approvers. `Any` returns merge requests with an approver. Premium and Ultimate only. |
| `approved`                      | string         | No       | Filters merge requests by their `approved` status. `yes` returns only approved merge requests. `no` returns only non-approved merge requests. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/3159) in GitLab 15.11. Available only when the feature flag `mr_approved_filter` is enabled. |
| `assignee_id`                   | integer        | No       | Returns merge requests assigned to the given user `id`. `None` returns unassigned merge requests. `Any` returns merge requests with an assignee. |
| `author_id`                     | integer        | No       | Returns merge requests created by the given user `id`. Mutually exclusive with `author_username`. |
| `author_username`               | string         | No       | Returns merge requests created by the given `username`. Mutually exclusive with `author_id`. |
| `created_after`                 | datetime       | No       | Returns merge requests created on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `created_before`                | datetime       | No       | Returns merge requests created on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `environment`                   | string         | No       | Returns merge requests deployed to the given environment. |
| `iids[]`                        | integer array  | No       | Returns the request having the given `iid`. |
| `labels`                        | string         | No       | Returns merge requests matching a comma-separated list of labels. `None` lists all merge requests with no labels. `Any` lists all merge requests with at least one label. Predefined names are case-insensitive. |
| `merge_user_id`                 | integer        | No       | Returns merge requests merged by the user with the given user `id`. Mutually exclusive with `merge_user_username`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002) in GitLab 17.0. |
| `merge_user_username`           | string         | No       | Returns merge requests merged by the user with the given `username`. Mutually exclusive with `merge_user_id`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002) in GitLab 17.0. |
| `milestone`                     | string         | No       | Returns merge requests for a specific milestone. `None` returns merge requests with no milestone. `Any` returns merge requests that have an assigned milestone. |
| `my_reaction_emoji`             | string         | No       | Returns merge requests reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction. |
| `not`                           | Hash           | No       | Returns merge requests that do not match the parameters supplied. Accepts: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `reviewer_id`, `reviewer_username`, `my_reaction_emoji`. |
| `order_by`                      | string         | No       | Returns requests ordered by `created_at`, `title` or `updated_at` fields. Default is `created_at`. |
| `page`                          | integer        | No       | The page of results to return. Defaults to 1. |
| `per_page`                      | integer        | No       | The number of results per page. Defaults to 20. |
| `reviewer_id`                   | integer        | No       | Returns merge requests which have the user as a [reviewer](../user/project/merge_requests/reviews/_index.md) with the given user `id`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer. Mutually exclusive with `reviewer_username`.  |
| `reviewer_username`             | string         | No       | Returns merge requests which have the user as a [reviewer](../user/project/merge_requests/reviews/_index.md) with the given `username`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer. Mutually exclusive with `reviewer_id`. |
| `scope`                         | string         | No       | Returns merge requests for the given scope: `created_by_me`, `assigned_to_me`, or `all`. |
| `search`                        | string         | No       | Search merge requests against their `title` and `description`. |
| `sort`                          | string         | No       | Returns requests sorted in `asc` or `desc` order. Default is `desc`. |
| `source_branch`                 | string         | No       | Returns merge requests with the given source branch. |
| `state`                         | string         | No       | Returns all merge requests (`all`) or just those that are `opened`, `closed`, `locked`, or `merged`.  |
| `target_branch`                 | string         | No       | Returns merge requests with the given target branch. |
| `updated_after`                 | datetime       | No       | Returns merge requests updated on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `updated_before`                | datetime       | No       | Returns merge requests updated on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `view`                          | string         | No       | If `simple`, returns the `iid`, URL, title, description, and basic state of merge request. |
| `wip`                           | string         | No       | Filter merge requests against their `wip` status. `yes` to return *only* draft merge requests, `no` to return *non-draft* merge requests. |
| `with_labels_details`           | boolean        | No       | If `true`, response returns more details for each label in labels field: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. Default is `false`. |
| `with_merge_status_recheck`     | boolean        | No       | If `true`, this projection requests (but does not guarantee) the asynchronous recalculation of the `merge_status` field. Default is `false`. In GitLab 15.11 and later, enable the `restrict_merge_status_recheck` feature [flag](../administration/feature_flags.md) to ignore this attribute when requested by users without at least the Developer role. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                          | Type     | Description |
| ---------------------------------- | -------- | ----------- |
| `[].id`                            | integer  | ID of the merge request. |
| `[].iid`                           | integer  | Internal ID of the merge request. |
| `[].approvals_before_merge`        | integer  | Number of approvals required before this merge request can merge. To configure approval rules, see [Merge request approvals API](merge_request_approvals.md). [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) in GitLab 16.0. Premium and Ultimate only. |
| `[].assignee`                      | object   | First assignee of the merge request. |
| `[].assignees`                     | array    | Assignees of the merge request. |
| `[].author`                        | object   | User who created this merge request. |
| `[].blocking_discussions_resolved` | boolean  | Indicates if all discussions are resolved only if all are required before merge request can be merged. |
| `[].closed_at`                     | datetime | Timestamp of when the merge request was closed. |
| `[].closed_by`                     | object   | User who closed this merge request. |
| `[].created_at`                    | datetime | Timestamp of when the merge request was created. |
| `[].description`                   | string   | Description of the merge request. |
| `[].detailed_merge_status`         | string   | Detailed merge status of the merge request. See [merge status](#merge-status) for a list of potential values. |
| `[].discussion_locked`             | boolean  | Indicates if comments on the merge request are locked to members only. |
| `[].downvotes`                     | integer  | Number of downvotes for the merge request. |
| `[].draft`                         | boolean  | Indicates if the merge request is a draft. |
| `[].force_remove_source_branch`    | boolean  | Indicates if the project settings lead to source branch deletion after merge. |
| `[].has_conflicts`                 | boolean  | Indicates if merge request has conflicts and cannot merge. Dependent on the `merge_status` property. Returns `false` unless `merge_status` is `cannot_be_merged`. |
| `[].labels`                        | array    | Labels of the merge request. |
| `[].merge_commit_sha`              | string   | SHA of the merge request commit. Returns `null` until merged. |
| `[].merge_status`                  | string   | Status of the merge request. Can be `unchecked`, `checking`, `can_be_merged`, `cannot_be_merged`, or `cannot_be_merged_recheck`. Affects the `has_conflicts` property. For important notes on response data, see [Single merge request response notes](#single-merge-request-response-notes). [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204) in GitLab 15.6. Use `detailed_merge_status` instead. |
| `[].merge_user`                    | object   | User who merged this merge request, the user who set it to auto-merge, or `null`. |
| `[].merge_when_pipeline_succeeds`  | boolean  | Indicates if the merge has been set to merge when its pipeline succeeds. |
| `[].merged_at`                     | datetime | Timestamp of when the merge request was merged. |
| `[].merged_by`                     | object   | User who merged this merge request or set it to auto-merge. [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/350534) in GitLab 14.7, and scheduled for removal in [API version 5](https://gitlab.com/groups/gitlab-org/-/epics/8115). Use `merge_user` instead. |
| `[].milestone`                     | object   | Milestone of the merge request. |
| `[].prepared_at`                   | datetime | Timestamp of when the merge request was prepared. This field is populated one time, only after all the [preparation steps](#preparation-steps) are completed, and is not updated if more changes are added. |
| `[].project_id`                    | integer  | ID of the project where the merge request resides. Always equal to `target_project_id`. |
| `[].reference`                     | string   | Internal reference of the merge request. Returned in shortened format by default. [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20354) in GitLab 12.7, and scheduled for removal in [API version 5](https://gitlab.com/groups/gitlab-org/-/epics/8115). Use `references` instead. |
| `[].references`                    | object   | Internal references of the merge request. Includes `short`, `relative`, and `full` references. `references.relative` is relative to the merge request's group or project. When fetched from the merge request's project, `relative` and `short` formats are identical. When requested across groups or projects, `relative` and `full` formats are identical.|
| `[].reviewers`                     | array    | Reviewers of the merge request. |
| `[].sha`                           | string   | Diff head SHA of the merge request. |
| `[].should_remove_source_branch`   | boolean  | Indicates if the source branch of the merge request should be deleted after merge. |
| `[].source_branch`                 | string   | Source branch of the merge request. |
| `[].source_project_id`             | integer  | ID of the merge request source project. Equal to `target_project_id`, unless the merge request originates from a fork. |
| `[].squash`                        | boolean  | If `true`, squash all commits into a single commit on merge. [Project settings](../user/project/merge_requests/squash_and_merge.md#configure-squash-options-for-a-project) might override this value. Use `squash_on_merge` instead to take project squash options into account. |
| `[].squash_commit_sha`             | string   | SHA of the squash commit. Empty until merged. |
| `[].squash_on_merge`               | boolean  | Indicates whether to squash the merge request when merging. |
| `[].state`                         | string   | State of the merge request. Can be `opened`, `closed`, `merged`, `locked`. |
| `[].target_branch`                 | string   | Target branch of the merge request. |
| `[].target_project_id`             | integer  | ID of the merge request target project. |
| `[].task_completion_status`        | object   | Completion status of tasks. Includes `count` and `completed_count`. |
| `[].time_stats`                    | object   | Time tracking stats of the merge request. Includes `time_estimate`, `total_time_spent`, `human_time_estimate`, and `human_total_time_spent`. |
| `[].title`                         | string   | Title of the merge request. |
| `[].updated_at`                    | datetime | Timestamp of when the merge request was updated. |
| `[].upvotes`                       | integer  | Number of upvotes for the merge request. |
| `[].user_notes_count`              | integer  | User notes count of the merge request. |
| `[].web_url`                       | string   | Web URL of the merge request. |
| `[].work_in_progress`              | boolean  | Deprecated: Use `draft` instead. Indicates if the merge request is a draft. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests"
```

Example response:

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 3,
    "title": "test1",
    "description": "fixed login page css paddings",
    "state": "merged",
    "imported": false,
    "imported_from": "none",
    "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "locked": false,
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merge_user": {
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "locked": false,
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merged_at": "2018-09-07T11:16:17.520Z",
    "merge_after": "2018-09-07T11:16:00.000Z",
    "prepared_at": "2018-09-04T11:16:17.520Z",
    "closed_by": null,
    "closed_at": null,
    "created_at": "2017-04-29T08:46:00Z",
    "updated_at": "2017-04-29T08:46:00Z",
    "target_branch": "main",
    "source_branch": "test1",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "locked": false,
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignee": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "locked": false,
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignees": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "locked": false,
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
    "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
    "reference": "!1",
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
    "squash_on_merge": false,
    "task_completion_status":{
      "count":0,
      "completed_count":0
    },
    "has_conflicts": false,
    "blocking_discussions_resolved": true,
    "approvals_before_merge": 2
  }
]
```

For important notes on response data, see [Merge requests list response notes](#merge-requests-list-response-notes).

## List group merge requests

Get all merge requests for this group and its subgroups.

```plaintext
GET /groups/:id/merge_requests
GET /groups/:id/merge_requests?state=opened
GET /groups/:id/merge_requests?state=all
GET /groups/:id/merge_requests?milestone=release
GET /groups/:id/merge_requests?labels=bug,reproduced
GET /groups/:id/merge_requests?my_reaction_emoji=star
```

Supported attributes:

| Attribute                       | Type           | Required | Description |
| ------------------------------- | -------------- | -------- | ----------- |
| `id`                            | integer or string | Yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `approved_by_ids`               | integer array  | No       | Returns the merge requests approved by all the users with the given `id`, up to 5 users. `None` returns merge requests with no approvals. `Any` returns merge requests with an approval. Premium and Ultimate only. |
| `approved_by_usernames`         | string array  | No       | Returns the merge requests approved by all the users with the given `username`, up to 5 users. `None` returns merge requests with no approvals. `Any` returns merge requests with an approval. Premium and Ultimate only. |
| `approver_ids`                  | integer array  | No       | Returns merge requests which have specified all the users with the given `id` as individual approvers. `None` returns merge requests without approvers. `Any` returns merge requests with an approver. Premium and Ultimate only. |
| `approved`                      | string         | No       | Filters merge requests by their `approved` status. `yes` returns only approved merge requests. `no` returns only non-approved merge requests. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/3159) in GitLab 15.11. Available only when the feature flag `mr_approved_filter` is enabled. |
| `assignee_id`                   | integer        | No       | Returns merge requests assigned to the given user `id`. `None` returns unassigned merge requests. `Any` returns merge requests with an assignee. |
| `author_id`                     | integer        | No       | Returns merge requests created by the given user `id`. Mutually exclusive with `author_username`. |
| `author_username`               | string         | No       | Returns merge requests created by the given `username`. Mutually exclusive with `author_id`. |
| `created_after`                 | datetime       | No       | Returns merge requests created on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `created_before`                | datetime       | No       | Returns merge requests created on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `labels`                        | string         | No       | Returns merge requests matching a comma-separated list of labels. `None` lists all merge requests with no labels. `Any` lists all merge requests with at least one label. Predefined names are case-insensitive. |
| `merge_user_id`                 | integer        | No       | Returns merge requests merged by the user with the given user `id`. Mutually exclusive with `merge_user_username`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002) in GitLab 17.0. |
| `merge_user_username`           | string         | No       | Returns merge requests merged by the user with the given `username`. Mutually exclusive with `merge_user_id`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002) in GitLab 17.0. |
| `milestone`                     | string         | No       | Returns merge requests for a specific milestone. `None` returns merge requests with no milestone. `Any` returns merge requests that have an assigned milestone. |
| `my_reaction_emoji`             | string         | No       | Returns merge requests reacted by the authenticated user by the given `emoji`. `None` returns issues not given a reaction. `Any` returns issues given at least one reaction. |
| `non_archived`                  | boolean        | No       | Returns merge requests from non archived projects only. Default is `true`. |
| `not`                           | Hash           | No       | Returns merge requests that do not match the parameters supplied. Accepts: `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `reviewer_id`, `reviewer_username`, `my_reaction_emoji`. |
| `order_by`                      | string         | No       | Returns merge requests ordered by `created_at`, `title` or `updated_at` fields. Default is `created_at`. |
| `reviewer_id`                   | integer        | No       | Returns merge requests which have the user as a [reviewer](../user/project/merge_requests/reviews/_index.md) with the given user `id`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer. Mutually exclusive with `reviewer_username`. |
| `reviewer_username`             | string         | No       | Returns merge requests which have the user as a [reviewer](../user/project/merge_requests/reviews/_index.md) with the given `username`. `None` returns merge requests with no reviewers. `Any` returns merge requests with any reviewer. Mutually exclusive with `reviewer_id`. |
| `scope`                         | string         | No       | Returns merge requests for the given scope: `created_by_me`, `assigned_to_me` or `all`. |
| `search`                        | string         | No       | Search merge requests against their `title` and `description`. |
| `source_branch`                 | string         | No       | Returns merge requests with the given source branch. |
| `sort`                          | string         | No       | Returns merge requests sorted in `asc` or `desc` order. Default is `desc`. |
| `state`                         | string         | No       | Returns all merge requests (`all`) or just those that are `opened`, `closed`, `locked`, or `merged`. |
| `target_branch`                 | string         | No       | Returns merge requests with the given target branch. |
| `updated_after`                 | datetime       | No       | Returns merge requests updated on or after the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `updated_before`                | datetime       | No       | Returns merge requests updated on or before the given time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `view`                          | string         | No       | If `simple`, returns the `iid`, URL, title, description, and basic state of merge request. |
| `with_labels_details`           | boolean        | No       | If `true`, response returns more details for each label in labels field: `:name`, `:color`, `:description`, `:description_html`, `:text_color`. Default is `false`. |
| `with_merge_status_recheck`     | boolean        | No       | If `true`, this projection requests (but does not guarantee) the asynchronous recalculation of the `merge_status` field. Default is `false`. In GitLab 15.11 and later, enable the `restrict_merge_status_recheck` feature [flag](../administration/feature_flags.md) to ignore this attribute when requested by users without at least the Developer role. |

To restrict the list of merge requests, use the pagination parameters `page` and `per_page`.

In the response, `group_id` represents the ID of the group containing the project where the merge request resides.

Example response:

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 3,
    "title": "test1",
    "description": "fixed login page css paddings",
    "state": "merged",
    "imported": false,
    "imported_from": "none",
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
    "merge_after": "2018-09-07T11:16:00.000Z",
    "prepared_at": "2018-09-04T11:16:17.520Z",
    "closed_by": null,
    "closed_at": null,
    "created_at": "2017-04-29T08:46:00Z",
    "updated_at": "2017-04-29T08:46:00Z",
    "target_branch": "main",
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

For important notes on response data, see [Merge requests list response notes](#merge-requests-list-response-notes).

## Get single MR

Shows information about a single merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid
```

Supported attributes:

| Attribute                        | Type           | Required | Description |
|----------------------------------|----------------|----------|-------------|
| `id`                             | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid`              | integer        | Yes      | The internal ID of the merge request. |
| `include_diverged_commits_count` | boolean        | No       | If `true`, response includes the commits behind the target branch. |
| `include_rebase_in_progress`     | boolean        | No       | If `true`, response includes whether a rebase operation is in progress. |
| `render_html`                    | boolean        | No       | If `true`, response includes rendered HTML for title and description. |

### Response

| Attribute                        | Type | Description |
|----------------------------------|------|-------------|
| `approvals_before_merge`| integer | Number of approvals required before this merge request can merge. To configure approval rules, see [Merge request approvals API](merge_request_approvals.md). [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) in GitLab 16.0. Premium and Ultimate only. |
| `assignee` | object | First assignee of the merge request. |
| `assignees` | array | Assignees of the merge request. |
| `author` | object | User who created this merge request. |
| `blocking_discussions_resolved` | boolean | Indicates if all discussions are resolved only if all are required before merge request can be merged. |
| `changes_count` | string | Number of changes made on the merge request. Empty when the merge request is created, and populates asynchronously. A string, not an integer. When a merge request has too many changes to display and store, the value is capped at 1000 and returns the string `"1000+"`. See [Empty API Fields for new merge requests](#empty-api-fields-for-new-merge-requests).|
| `closed_at` | datetime | Timestamp of when the merge request was closed. |
| `closed_by` | object | User who closed this merge request. |
| `created_at` | datetime | Timestamp of when the merge request was created. |
| `description` | string | Description of the merge request. Contains Markdown rendered as HTML for caching. |
| `detailed_merge_status` | string | Detailed merge status of the merge request. See [merge status](#merge-status) for a list of potential values. |
| `diff_refs` | object | References of the base SHA, the head SHA, and the start SHA for this merge request. Corresponds to the latest diff version of the merge request. Empty when the merge request is created, and populates asynchronously. See [Empty API fields for new merge requests](#empty-api-fields-for-new-merge-requests). |
| `discussion_locked` | boolean | Indicates if comments on the merge request are locked to members only. |
| `downvotes` | integer | Number of downvotes for the merge request. |
| `draft` | boolean | Indicates if the merge request is a draft. |
| `first_contribution` | boolean | Indicates if the merge request is the first contribution of the author. |
| `first_deployed_to_production_at` | datetime | Timestamp of when the first deployment finished. |
| `force_remove_source_branch` | boolean | Indicates if the project settings lead to source branch deletion after merge. |
| `has_conflicts` | boolean | Indicates if merge request has conflicts and cannot merge. Dependent on the `merge_status` property. Returns `false` unless `merge_status` is `cannot_be_merged`. |
| `head_pipeline` | object | Pipeline running on the branch HEAD of the merge request. Use instead of `pipeline`, because it contains more complete information. |
| `id` | integer | ID of the merge request. |
| `iid` | integer | Internal ID of the merge request. |
| `labels` | array | Labels of the merge request. |
| `latest_build_finished_at` | datetime | Timestamp of when the latest build for the merge request finished. |
| `latest_build_started_at` | datetime | Timestamp of when the latest build for the merge request started. |
| `merge_commit_sha` | string | SHA of the merge request commit. Returns `null` until merged. |
| `merge_error` | string | Error message shown when a merge has failed. To check mergeability, use `detailed_merge_status` instead  |
| `merge_user` | object | The user who merged this merge request, the user who set it to auto-merge, or `null`.  |
| `merge_status` | string | Status of the merge request. Can be `unchecked`, `checking`, `can_be_merged`, `cannot_be_merged`, or `cannot_be_merged_recheck`. Affects the `has_conflicts` property. For important notes on response data, see [Single merge request response notes](#single-merge-request-response-notes). [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204) in GitLab 15.6. Use `detailed_merge_status` instead. |
| `merge_when_pipeline_succeeds` | boolean | Indicates if the merge is set to merge when its pipeline succeeds. |
| `merged_at` | datetime | Timestamp of when the merge request merged. |
| `merged_by` | object | User who merged this merge request or set it to auto-merge. [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/350534) in GitLab 14.7, and scheduled for removal in [API version 5](https://gitlab.com/groups/gitlab-org/-/epics/8115). Use `merge_user` instead. |
| `milestone` | object | Milestone of the merge request. |
| `pipeline` | object | Pipeline running on the branch HEAD of the merge request. Consider using `head_pipeline` instead, as it contains more information. |
| `prepared_at` | datetime | Timestamp of when the merge request was prepared. This field populates one time, only after all the [preparation steps](#preparation-steps) complete, and is not updated if more changes are added. |
| `project_id` | integer | ID of the merge request project. |
| `reference` | string | Internal reference of the merge request. Returned in shortened format by default. [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20354) in GitLab 12.7, and scheduled for removal in [API version 5](https://gitlab.com/groups/gitlab-org/-/epics/8115). Use `references` instead. |
| `references` | object | Internal references of the merge request. Includes `short`, `relative`, and `full` references. `references.relative` is relative to the merge request's group or project. When fetched from the merge request's project, `relative` and `short` formats are identical. When requested across groups or projects, `relative` and `full` formats are identical.|
| `reviewers` | array | Reviewers of the merge request. |
| `sha` | string | Diff head SHA of the merge request. |
| `should_remove_source_branch` | boolean | Indicates if the source branch of the merge request should be deleted after merge. |
| `source_branch` | string | Source branch of the merge request. |
| `source_project_id` | integer | ID of the merge request source project. |
| `squash` | boolean | Indicates if squash on merge is enabled. |
| `squash_commit_sha` | string | SHA of the squash commit. Empty until merged. |
| `state` | string | State of the merge request. Can be `opened`, `closed`, `merged` or `locked`. |
| `subscribed` | boolean | Indicates if the current authenticated user subscribes to this merge request. |
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

Example response:

```json
{
  "id": 155016530,
  "iid": 133,
  "project_id": 15513260,
  "title": "Manual job rules",
  "description": "",
  "state": "opened",
  "imported": false,
  "imported_from": "none",
  "created_at": "2022-05-13T07:26:38.402Z",
  "updated_at": "2022-05-14T03:38:31.354Z",
  "merged_by": null, // Deprecated and will be removed in API v5. Use `merge_user` instead.
  "merge_user": null,
  "merged_at": null,
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "target_branch": "main",
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

The mergeability (`merge_status`)
of each merge request is checked asynchronously when a request is made to this endpoint. Poll this API endpoint
to get the updated status. This affects the `has_conflicts` property, as it depends on the `merge_status`. It returns
`false` unless `merge_status` is `cannot_be_merged`.

### Merge status

> - `merge_status` [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204) in GitLab 15.6.
> - `detailed_merge_status` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101724) in GitLab 15.6.

Use `detailed_merge_status` instead of `merge_status` to account for all potential statuses.

- The `detailed_merge_status` field can contain one of the following values related to the merge request:
  - `approvals_syncing`: The merge request's approvals are syncing.
  - `checking`: Git is testing if a valid merge is possible.
  - `ci_must_pass`: A CI/CD pipeline must succeed before merge.
  - `ci_still_running`: A CI/CD pipeline is still running.
  - `commits_status`: Source branch should exist, and contain commits.
  - `conflict`: Conflicts exist between the source and target branches.
  - `discussions_not_resolved`: All discussions must be resolved before merge.
  - `draft_status`: Can't merge because the merge request is a draft.
  - `jira_association_missing`: The title or description must reference a Jira issue. To configure, see
    [Require associated Jira issue for merge requests to be merged](../integration/jira/issues.md#require-associated-jira-issue-for-merge-requests-to-be-merged).
  - `mergeable`: The branch can merge cleanly into the target branch.
  - `merge_request_blocked`: Blocked by another merge request.
  - `merge_time`: May not be merged until after the specified time.
  - `need_rebase`: The merge request must be rebased.
  - `not_approved`: Approval is required before merge.
  - `not_open`: The merge request must be open before merge.
  - `preparing`: Merge request diff is being created.
  - `requested_changes`: The merge request has reviewers who have requested changes.
  - `security_policy_violations`: All security policies must be satisfied.
    Requires the `policy_mergability_check` feature flag to be enabled.
  - `status_checks_must_pass`: All status checks must pass before merge.
  - `unchecked`: Git has not yet tested if a valid merge is possible.
  - `locked_paths`: Paths locked by other users must be unlocked before merging to default branch.
  - `locked_lfs_files`: LFS files locked by other users must be unlocked before merge.

### Preparation steps

The `prepared_at` field populates one time, only after these steps complete:

- Create the diff.
- Create the pipelines.
- Check mergeability.
- Link all Git LFS objects.
- Send notifications.

The `prepared_at` field does not update if more changes are added to the merge request.

## Get single merge request participants

Get a list of merge request participants.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/participants
```

Supported attributes:

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer           | Yes      | The internal ID of the merge request. |

Example response:

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

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer           | Yes      | The internal ID of the merge request. |

Example response:

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

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer           | Yes      | Internal ID of the merge request. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                     | Type         | Description |
|-------------------------------|--------------|-------------|
| `commits`                     | object array | Commits in the merge request. |
| `commits[].id`                | string       | ID of the commit. |
| `commits[].short_id`          | string       | Short ID of the commit. |
| `commits[].created_at`        | datetime     | Identical to the `committed_date` field. |
| `commits[].parent_ids`        | array        | IDs of the parent commits. |
| `commits[].title`             | string       | Commit title. |
| `commits[].message`           | string       | Commit message. |
| `commits[].author_name`       | string       | Commit author's name. |
| `commits[].author_email`      | string       | Commit author's email address. |
| `commits[].authored_date`     | datetime     | Commit authored date. |
| `commits[].committer_name`    | string       | Name of the committer. |
| `commits[].committer_email`   | string       | Email address of the committer. |
| `commits[].committed_date`    | datetime     | Commit date. |
| `commits[].trailers`          | object       | Git trailers parsed for the commit. Duplicate keys include the last value only. |
| `commits[].extended_trailers` | object       | Git trailers parsed for the commit. |
| `commits[].web_url`           | string       | Web URL of the merge request. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/commits"
```

Example response:

```json
[
  {
    "id": "ed899a2f4b50b4370feeea94676502b42383c746",
    "short_id": "ed899a2f4b5",
    "title": "Replace sanitize with escape once",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "authored_date": "2012-09-20T11:50:22+03:00",
    "committer_name": "Example User",
    "committer_email": "user@example.com",
    "committed_date": "2012-09-20T11:50:22+03:00",
    "created_at": "2012-09-20T11:50:22+03:00",
    "message": "Replace sanitize with escape once",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/project/-/commit/ed899a2f4b50b4370feeea94676502b42383c746"
  },
  {
    "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
    "short_id": "6104942438c",
    "title": "Sanitize for network graph",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "authored_date": "2012-09-20T09:06:12+03:00",
    "committer_name": "Example User",
    "committer_email": "user@example.com",
    "committed_date": "2012-09-20T09:06:12+03:00",
    "created_at": "2012-09-20T09:06:12+03:00",
    "message": "Sanitize for network graph",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/project/-/commit/6104942438c14ec7bd21c6cd5bd995272b3faff6"
  }
]
```

## Get merge request dependencies

Shows information about the merge request dependencies that must be resolved before merging.

NOTE:
If the user does not have access to the blocking merge request, no `blocking_merge_request`
attribute is returned.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/blocks
```

Supported attributes:

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blocks"
```

Example response:

```json
[
  {
    "id": 1,
    "blocking_merge_request": {
      "id": 145,
      "iid": 12,
      "project_id": 7,
      "title": "Interesting MR",
      "description": "Does interesting things.",
      "state": "opened",
      "created_at": "2024-07-05T21:29:11.172Z",
      "updated_at": "2024-07-05T21:29:11.172Z",
      "merged_by": null,
      "merge_user": null,
      "merged_at": null,
      "merge_after": "2018-09-07T11:16:00.000Z",
      "closed_by": null,
      "closed_at": null,
      "target_branch": "master",
      "source_branch": "v2.x",
      "user_notes_count": 0,
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      "assignees": [
        {
          "id": 2,
          "username": "aiguy123",
          "name": "AI GUY",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhost/aiguy123"
        }
      ],
      "assignee": {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      "reviewers": [
        {
          "id": 2,
          "username": "aiguy123",
          "name": "AI GUY",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhost/aiguy123"
        },
        {
          "id": 1,
          "username": "root",
          "name": "Administrator",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhost/root"
        }
      ],
      "source_project_id": 7,
      "target_project_id": 7,
      "labels": [],
      "draft": false,
      "imported": false,
      "imported_from": "none",
      "work_in_progress": false,
      "milestone": null,
      "merge_when_pipeline_succeeds": false,
      "merge_status": "unchecked",
      "detailed_merge_status": "unchecked",
      "sha": "ce7e4f2d0ce13cb07479bb39dc10ee3b861c08a6",
      "merge_commit_sha": null,
      "squash_commit_sha": null,
      "discussion_locked": null,
      "should_remove_source_branch": null,
      "force_remove_source_branch": true,
      "prepared_at": null,
      "reference": "!12",
      "references": {
        "short": "!12",
        "relative": "!12",
        "full": "my-group/my-project!12"
      },
      "web_url": "https://localhost/my-group/my-project/-/merge_requests/12",
      "time_stats": {
        "time_estimate": 0,
        "total_time_spent": 0,
        "human_time_estimate": null,
        "human_total_time_spent": null
      },
      "squash": false,
      "squash_on_merge": false,
      "task_completion_status": {
        "count": 0,
        "completed_count": 0
      },
      "has_conflicts": false,
      "blocking_discussions_resolved": true,
      "approvals_before_merge": null
    },
    "blocked_merge_request": {
      "id": 146,
      "iid": 13,
      "project_id": 7,
      "title": "Really cool MR",
      "description": "Adds some stuff",
      "state": "opened",
      "created_at": "2024-07-05T21:31:34.811Z",
      "updated_at": "2024-07-27T02:57:08.054Z",
      "merged_by": null,
      "merge_user": null,
      "merged_at": null,
      "merge_after": "2018-09-07T11:16:00.000Z",
      "closed_by": null,
      "closed_at": null,
      "target_branch": "master",
      "source_branch": "remove-from",
      "user_notes_count": 0,
      "upvotes": 1,
      "downvotes": 0,
      "author": {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      "assignees": [
        {
          "id": 2,
          "username": "aiguy123",
          "name": "AI GUY",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhose/aiguy123"
        }
      ],
      "assignee": {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      "reviewers": [
        {
          "id": 1,
          "username": "root",
          "name": "Administrator",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhost/root"
        }
      ],
      "source_project_id": 7,
      "target_project_id": 7,
      "labels": [],
      "draft": false,
      "imported": false,
      "imported_from": "none",
      "work_in_progress": false,
      "milestone": {
        "id": 59,
        "iid": 6,
        "project_id": 7,
        "title": "Sprint 1718897375",
        "description": "Accusantium omnis iusto a animi.",
        "state": "active",
        "created_at": "2024-06-20T15:29:35.739Z",
        "updated_at": "2024-06-20T15:29:35.739Z",
        "due_date": null,
        "start_date": null,
        "expired": false,
        "web_url": "https://localhost/my-group/my-project/-/milestones/6"
      },
      "merge_when_pipeline_succeeds": false,
      "merge_status": "cannot_be_merged",
      "detailed_merge_status": "not_approved",
      "sha": "daa75b9b17918f51f43866ff533987fda71375ea",
      "merge_commit_sha": null,
      "squash_commit_sha": null,
      "discussion_locked": null,
      "should_remove_source_branch": null,
      "force_remove_source_branch": true,
      "prepared_at": "2024-07-11T18:50:46.215Z",
      "reference": "!13",
      "references": {
        "short": "!13",
        "relative": "!13",
        "full": "my-group/my-project!12"
      },
      "web_url": "https://localhost/my-group/my-project/-/merge_requests/13",
      "time_stats": {
        "time_estimate": 0,
        "total_time_spent": 0,
        "human_time_estimate": null,
        "human_total_time_spent": null
      },
      "squash": false,
      "squash_on_merge": false,
      "task_completion_status": {
        "count": 0,
        "completed_count": 0
      },
      "has_conflicts": true,
      "blocking_discussions_resolved": true,
      "approvals_before_merge": null
    },
    "project_id": 7
  }
]
```

## Delete a merge request dependency

Delete a merge request dependency.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/blocks/:block_id
```

Supported attributes:

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) owned by the authenticated user. |
| `merge_request_iid` | integer        | Yes      | The internal ID of the merge request. |
| `block_id`          | integer        | Yes      | The internal ID of the block. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blocks/1"
```

Returns:

- `204 No Content` if the dependency is successfully deleted.
- `403 Forbidden` if the user lacks permissions for updating the merge request.
- `403 Forbidden` if the user lacks permissions for reading the blocking merge request.

## Create a merge request dependency

Create a merge request dependency.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/blocks
```

Supported attributes:

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) owned by the authenticated user. |
| `merge_request_iid` | integer        | Yes      | The internal ID of the merge request. |
| `blocking_merge_request_id`          | integer        | Yes      | The internal ID of the blocking merge request. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blocks?blocking_merge_request_id=2"
```

Returns:

- `201 Created` if the dependency is successfully created.
- `400 Bad request` if the blocking merge request fails to save.
- `403 Forbidden` if the user lacks permissions for reading the blocking merge request.
- `404 Not found` if the blocking merge request is not found.
- `409 Conflict` if the block already exists.

Example response:

```json
[
  {
    "id": 1,
    "blocking_merge_request": {
      "id": 145,
      "iid": 12,
      "project_id": 7,
      "title": "Interesting MR",
      "description": "Does interesting things.",
      "state": "opened",
      "created_at": "2024-07-05T21:29:11.172Z",
      "updated_at": "2024-07-05T21:29:11.172Z",
      "merged_by": null,
      "merge_user": null,
      "merged_at": null,
      "merge_after": "2018-09-07T11:16:00.000Z",
      "closed_by": null,
      "closed_at": null,
      "target_branch": "master",
      "source_branch": "v2.x",
      "user_notes_count": 0,
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      "assignees": [
        {
          "id": 2,
          "username": "aiguy123",
          "name": "AI GUY",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhost/aiguy123"
        }
      ],
      "assignee": {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      "reviewers": [
        {
          "id": 2,
          "username": "aiguy123",
          "name": "AI GUY",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhost/aiguy123"
        },
        {
          "id": 1,
          "username": "root",
          "name": "Administrator",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhost/root"
        }
      ],
      "source_project_id": 7,
      "target_project_id": 7,
      "labels": [],
      "draft": false,
      "imported": false,
      "imported_from": "none",
      "work_in_progress": false,
      "milestone": null,
      "merge_when_pipeline_succeeds": false,
      "merge_status": "unchecked",
      "detailed_merge_status": "unchecked",
      "sha": "ce7e4f2d0ce13cb07479bb39dc10ee3b861c08a6",
      "merge_commit_sha": null,
      "squash_commit_sha": null,
      "discussion_locked": null,
      "should_remove_source_branch": null,
      "force_remove_source_branch": true,
      "prepared_at": null,
      "reference": "!12",
      "references": {
        "short": "!12",
        "relative": "!12",
        "full": "my-group/my-project!12"
      },
      "web_url": "https://localhost/my-group/my-project/-/merge_requests/12",
      "time_stats": {
        "time_estimate": 0,
        "total_time_spent": 0,
        "human_time_estimate": null,
        "human_total_time_spent": null
      },
      "squash": false,
      "squash_on_merge": false,
      "task_completion_status": {
        "count": 0,
        "completed_count": 0
      },
      "has_conflicts": false,
      "blocking_discussions_resolved": true,
      "approvals_before_merge": null
    },
    "project_id": 7
  }
]
```

## Get merge request blocked MRs

Shows information about the merge requests blocked by the current merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/blockees
```

Supported attributes:

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blockees"
```

Example response:

```json
[
  {
    "id": 18,
    "blocking_merge_request": {
      "id": 71,
      "iid": 10,
      "project_id": 7,
      "title": "At quaerat occaecati voluptate ex explicabo nisi.",
      "description": "Aliquid distinctio officia corrupti ad nemo natus ipsum culpa.",
      "state": "merged",
      "created_at": "2024-07-05T19:44:14.023Z",
      "updated_at": "2024-07-05T19:44:14.023Z",
      "merged_by": {
        "id": 40,
        "username": "i-user-0-1720208283",
        "name": "I User0",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/8325417f0f7919e3724957543b4414fdeca612cade1e4c0be45685fdaa2be0e2?s=80&d=identicon",
        "web_url": "http://127.0.0.1:3000/i-user-0-1720208283"
      },
      "merge_user": {
        "id": 40,
        "username": "i-user-0-1720208283",
        "name": "I User0",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/8325417f0f7919e3724957543b4414fdeca612cade1e4c0be45685fdaa2be0e2?s=80&d=identicon",
        "web_url": "http://127.0.0.1:3000/i-user-0-1720208283"
      },
      "merged_at": "2024-06-26T19:44:14.123Z",
      "closed_by": null,
      "closed_at": null,
      "target_branch": "master",
      "source_branch": "Brickwood-Brunefunc-417",
      "user_notes_count": 0,
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "id": 40,
        "username": "i-user-0-1720208283",
        "name": "I User0",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/8325417f0f7919e3724957543b4414fdeca612cade1e4c0be45685fdaa2be0e2?s=80&d=identicon",
        "web_url": "http://127.0.0.1:3000/i-user-0-1720208283"
      },
      "assignees": [],
      "assignee": null,
      "reviewers": [],
      "source_project_id": 7,
      "target_project_id": 7,
      "labels": [],
      "draft": false,
      "imported": false,
      "imported_from": "none",
      "work_in_progress": false,
      "milestone": null,
      "merge_when_pipeline_succeeds": false,
      "merge_status": "can_be_merged",
      "detailed_merge_status": "not_open",
      "merge_after": null,
      "sha": null,
      "merge_commit_sha": null,
      "squash_commit_sha": null,
      "discussion_locked": null,
      "should_remove_source_branch": null,
      "force_remove_source_branch": null,
      "prepared_at": null,
      "reference": "!10",
      "references": {
        "short": "!10",
        "relative": "!10",
        "full": "flightjs/Flight!10"
      },
      "web_url": "http://127.0.0.1:3000/flightjs/Flight/-/merge_requests/10",
      "time_stats": {
        "time_estimate": 0,
        "total_time_spent": 0,
        "human_time_estimate": null,
        "human_total_time_spent": null
      },
      "squash": false,
      "squash_on_merge": false,
      "task_completion_status": {
        "count": 0,
        "completed_count": 0
      },
      "has_conflicts": false,
      "blocking_discussions_resolved": true,
      "approvals_before_merge": null
    },
    "blocked_merge_request": {
      "id": 176,
      "iid": 14,
      "project_id": 7,
      "title": "second_mr",
      "description": "Signed-off-by: Lucas Zampieri <lzampier@redhat.com>",
      "state": "opened",
      "created_at": "2024-07-08T19:12:29.089Z",
      "updated_at": "2024-08-27T19:27:17.045Z",
      "merged_by": null,
      "merge_user": null,
      "merged_at": null,
      "closed_by": null,
      "closed_at": null,
      "target_branch": "master",
      "source_branch": "second_mr",
      "user_notes_count": 0,
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "id": 1,
        "username": "root",
        "name": "Administrator",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/fc3634394c590e212d964e8e0a34c4d9b8c17c992f4d6d145d75f9c21c1c3b6e?s=80&d=identicon",
        "web_url": "http://127.0.0.1:3000/root"
      },
      "assignees": [],
      "assignee": null,
      "reviewers": [],
      "source_project_id": 7,
      "target_project_id": 7,
      "labels": [],
      "draft": false,
      "imported": false,
      "imported_from": "none",
      "work_in_progress": false,
      "milestone": null,
      "merge_when_pipeline_succeeds": false,
      "merge_status": "cannot_be_merged",
      "detailed_merge_status": "commits_status",
      "merge_after": null,
      "sha": "3a576801e528db79a75fbfea463673054ff224fb",
      "merge_commit_sha": null,
      "squash_commit_sha": null,
      "discussion_locked": null,
      "should_remove_source_branch": null,
      "force_remove_source_branch": true,
      "prepared_at": null,
      "reference": "!14",
      "references": {
        "short": "!14",
        "relative": "!14",
        "full": "flightjs/Flight!14"
      },
      "web_url": "http://127.0.0.1:3000/flightjs/Flight/-/merge_requests/14",
      "time_stats": {
        "time_estimate": 0,
        "total_time_spent": 0,
        "human_time_estimate": null,
        "human_total_time_spent": null
      },
      "squash": false,
      "squash_on_merge": false,
      "task_completion_status": {
        "count": 0,
        "completed_count": 0
      },
      "has_conflicts": true,
      "blocking_discussions_resolved": true,
      "approvals_before_merge": null
    },
    "project_id": 7
  }
]
```

## Get single merge request changes

WARNING:
This endpoint was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/322117) in GitLab 15.7
and [is scheduled for removal](rest/deprecations.md) in API v5. Use the
[List merge request diffs](#list-merge-request-diffs) endpoint instead.

Shows information about the merge request including its files and changes.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/changes
```

Supported attributes:

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer        | Yes      | The internal ID of the merge request. |
| `access_raw_diffs`  | boolean        | No       | Retrieve change diffs through Gitaly. |
| `unidiff`           | boolean        | No       | Present change diffs in the [unified diff](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html) format. Default is false. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610) in GitLab 16.5. |

Diffs associated with the set of changes have the same size limitations applied as other diffs
returned by the API or viewed through the UI. When these limits impact the results, the `overflow`
field contains a value of `true`. Retrieve the diff data without these limits by
adding the `access_raw_diffs` parameter, which accesses diffs not from the database, but from Gitaly directly.
This approach is generally slower and more resource-intensive, but isn't subject to size limits
placed on database-backed diffs. [Limits inherent to Gitaly](../development/merge_request_concepts/diffs/_index.md#diff-limits)
still apply.

Example response:

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
    "diff": "@@ -1 +1 @@\ -1.9.7\ +1.9.8",
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false
    }
  ],
  "overflow": false
}
```

## List merge request diffs

> - `generated_file` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141576) in GitLab 16.9 [with a flag](../administration/feature_flags.md) named `collapse_generated_diff_files`. Disabled by default.
> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/432670) in GitLab 16.10.
> - `generated_file` [generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148478) in GitLab 16.11. Feature flag `collapse_generated_diff_files` removed.

List diffs of the files changed in a merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/diffs
```

Supported attributes:

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer           | Yes      | The internal ID of the merge request. |
| `page`              | integer           | No       | The page of results to return. Defaults to 1. |
| `per_page`          | integer           | No       | The number of results per page. Defaults to 20. |
| `unidiff`           | boolean           | No       | Present diffs in the [unified diff](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html) format. Default is false. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610) in GitLab 16.5. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute      | Type    | Description |
|----------------|---------|-------------|
| `old_path`     | string  | Old path of the file. |
| `new_path`     | string  | New path of the file. |
| `a_mode`       | string  | Old file mode of the file. |
| `b_mode`       | string  | New file mode of the file. |
| `diff`         | string  | Diff representation of the changes made to the file. |
| `new_file`     | boolean | Indicates if the file has just been added. |
| `renamed_file` | boolean | Indicates if the file has been renamed. |
| `deleted_file` | boolean | Indicates if the file has been removed. |
| `generated_file` | boolean | Indicates if the file is [marked as generated](../user/project/merge_requests/changes.md#collapse-generated-files). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141576) in GitLab 16.9. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/diffs?page=1&per_page=2"
```

Example response:

```json
[
  {
    "old_path": "README",
    "new_path": "README",
    "a_mode": "100644",
    "b_mode": "100644",
    "diff": "@@ -1 +1 @@\ -Title\ +README",
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false,
    "generated_file": false
  },
  {
    "old_path": "VERSION",
    "new_path": "VERSION",
    "a_mode": "100644",
    "b_mode": "100644",
    "diff": "@@\ -1.9.7\ +1.9.8",
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false,
    "generated_file": false
  }
]
```

NOTE:
This endpoint is subject to [Merge requests diff limits](../administration/instance_limits.md#diff-limits).
Merge requests that exceed the diff limits return limited results.

## Show merge request raw diffs

Show raw diffs of the files changed in a merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/raw_diffs
```

Supported attributes:

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer           | Yes      | The internal ID of the merge request. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and a raw diff response to use programmatically:

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/raw_diffs"
```

Example response:

```diff
        diff --git a/lib/api/helpers.rb b/lib/api/helpers.rb
index 31525ad523553c8d7eff163db3e539058efd6d3a..f30e36d6fdf4cd4fa25f62e08ecdbf4a7b169681 100644
--- a/lib/api/helpers.rb
+++ b/lib/api/helpers.rb
@@ -944,6 +944,10 @@ def send_git_blob(repository, blob)
       body ''
     end

+    def send_git_diff(repository, diff_refs)
+      header(*Gitlab::Workhorse.send_git_diff(repository, diff_refs))
+    end
+
     def send_git_archive(repository, **kwargs)
       header(*Gitlab::Workhorse.send_git_archive(repository, **kwargs))

diff --git a/lib/api/merge_requests.rb b/lib/api/merge_requests.rb
index e02d9eea1852f19fe5311acda6aa17465eeb422e..f32b38585398a18fea75c11d7b8ebb730eeb3fab 100644
--- a/lib/api/merge_requests.rb
+++ b/lib/api/merge_requests.rb
@@ -6,6 +6,8 @@ class MergeRequests < ::API::Base
     include PaginationParams
     include Helpers::Unidiff

+    helpers ::API::Helpers::HeadersHelpers
+
     CONTEXT_COMMITS_POST_LIMIT = 20

     before { authenticate_non_get! }
```

NOTE:
This endpoint is subject to [Merge requests diff limits](../administration/instance_limits.md#diff-limits).
Merge requests that exceed the diff limits return limited results.

## List merge request pipelines

Get a list of merge request pipelines.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/pipelines
```

Supported attributes:

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer           | Yes      | The internal ID of the merge request. |

To restrict the list of merge request pipelines, use the pagination parameters `page` and
`per_page`.

Example response:

```json
[
  {
    "id": 77,
    "sha": "959e04d7c7a30600c894bd3c0cd0e1ce7f42c11d",
    "ref": "main",
    "status": "success"
  }
]
```

## Create merge request pipeline

Create a new [pipeline for a merge request](../ci/pipelines/merge_request_pipelines.md).
A pipeline created from this endpoint doesn't run a regular branch/tag pipeline.
To create jobs, configure `.gitlab-ci.yml` with `only: [merge_requests]`.

The new pipeline can be:

- A detached merge request pipeline.
- A [merged results pipeline](../ci/pipelines/merged_results_pipelines.md)
  if the [project setting is enabled](../ci/pipelines/merged_results_pipelines.md#enable-merged-results-pipelines).

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/pipelines
```

Supported attributes:

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer           | Yes      | The internal ID of the merge request. |

Example response:

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
| `id`                       | integer or string | Yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `source_branch`            | string  | Yes      | The source branch. |
| `target_branch`            | string  | Yes      | The target branch. |
| `title`                    | string  | Yes      | Title of MR. |
| `allow_collaboration`      | boolean | No       | Allow commits from members who can merge to the target branch. |
| `approvals_before_merge`   | integer | No | Number of approvals required before this merge request can merge (see below). To configure approval rules, see [Merge request approvals API](merge_request_approvals.md). [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) in GitLab 16.0. Premium and Ultimate only. |
| `allow_maintainer_to_push` | boolean | No       | Alias of `allow_collaboration`. |
| `assignee_id`              | integer | No       | Assignee user ID. |
| `assignee_ids`             | integer array | No | The ID of the users to assign the merge request to. Set to `0` or provide an empty value to unassign all assignees. |
| `description`              | string  | No       | Description of the merge request. Limited to 1,048,576 characters. |
| `labels`                   | string  | No       | Labels for the merge request, as a comma-separated list. If a label does not already exist, this creates a new project label and assigns it to the merge request. |
| `merge_after`              | string  | No       | Date after which the merge request can be merged. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/510992) in GitLab 17.8. |
| `milestone_id`             | integer | No       | The global ID of a milestone. |
| `remove_source_branch`     | boolean | No       | Flag indicating if a merge request should remove the source branch when merging. |
| `reviewer_ids`             | integer array | No | The ID of the users added as a reviewer to the merge request. If set to `0` or left empty, no reviewers are added. |
| `squash`                   | boolean | No       | If `true`, squash all commits into a single commit on merge. [Project settings](../user/project/merge_requests/squash_and_merge.md#configure-squash-options-for-a-project) might override this value. |
| `target_project_id`        | integer | No       | Numeric ID of the target project. |

Example response:

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "imported": false,
  "imported_from": "none",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "main",
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
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
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

For important notes on response data, see [Single merge request response notes](#single-merge-request-response-notes).

## Update MR

Updates an existing merge request. You can change the target branch, title, or even close the MR.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid
```

| Attribute                  | Type    | Required | Description |
| ---------                  | ----    | -------- | ----------- |
| `id`                       | integer or string | Yes  | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid`        | integer | Yes      | The ID of a merge request. |
| `add_labels`               | string  | No       | Comma-separated label names to add to a merge request. If a label does not already exist, this creates a new project label and assigns it to the merge request. |
| `allow_collaboration`      | boolean | No       | Allow commits from members who can merge to the target branch. |
| `allow_maintainer_to_push` | boolean | No       | Alias of `allow_collaboration`. |
| `assignee_id`              | integer | No       | The ID of the user to assign the merge request to. Set to `0` or provide an empty value to unassign all assignees. |
| `assignee_ids`             | integer array | No | The ID of the users to assign the merge request to. Set to `0` or provide an empty value to unassign all assignees. |
| `description`              | string  | No       | Description of the merge request. Limited to 1,048,576 characters. |
| `discussion_locked`        | boolean | No       | Flag indicating if the merge request's discussion is locked. Only project members can add, edit or resolve comments to locked discussions. |
| `labels`                   | string  | No       | Comma-separated label names for a merge request. Set to an empty string to unassign all labels. If a label does not already exist, this creates a new project label and assigns it to the merge request. |
| `merge_after`              | string  | No       | Date after which the merge request can be merged. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/510992) in GitLab 17.8. |
| `milestone_id`             | integer | No       | The global ID of a milestone to assign the merge request to. Set to `0` or provide an empty value to unassign a milestone.|
| `remove_labels`            | string  | No       | Comma-separated label names to remove from a merge request. |
| `remove_source_branch`     | boolean | No       | Flag indicating if a merge request should remove the source branch when merging. |
| `reviewer_ids`             | integer array | No | The ID of the users set as a reviewer to the merge request. Set the value to `0` or provide an empty value to unset all reviewers. |
| `squash`                   | boolean | No       | If `true`, squash all commits into a single commit on merge. [Project settings](../user/project/merge_requests/squash_and_merge.md#configure-squash-options-for-a-project) might override this value. |
| `state_event`              | string  | No       | New state (close/reopen). |
| `target_branch`            | string  | No       | The target branch. |
| `title`                    | string  | No       | Title of MR. |

Must include at least one non-required attribute from above.

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
  "target_branch": "main",
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
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
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

For important notes on response data, see [Single merge request response notes](#single-merge-request-response-notes).

## Delete a merge request

Only for administrators and project owners. Deletes the merge request in question.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid
```

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer           | Yes      | The internal ID of the merge request. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/merge_requests/85"
```

## Merge a merge request

Accept and merge changes submitted with merge request using this API.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/merge
```

Supported attributes:

| Attribute                      | Type           | Required | Description |
|--------------------------------|----------------|----------|-------------|
| `id`                           | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid`            | integer        | Yes      | The internal ID of the merge request. |
| `merge_commit_message`         | string         | No       | Custom merge commit message. |
| `merge_when_pipeline_succeeds` | boolean        | No       | If `true`, the merge request merges when the pipeline succeeds. |
| `sha`                          | string         | No       | If present, then this SHA must match the HEAD of the source branch, otherwise the merge fails. |
| `should_remove_source_branch`  | boolean        | No       | If `true`, removes the source branch. |
| `squash_commit_message`        | string         | No       | Custom squash commit message. |
| `squash`                       | boolean        | No       | If `true`, squash all commits into a single commit on merge. |

This API returns specific HTTP status codes on failure:

| HTTP Status | Message                                    | Reason |
|-------------|--------------------------------------------|--------|
| `401`       | `401 Unauthorized`                             | This user does not have permission to accept this merge request. |
| `405`       | `405 Method Not Allowed`                       | The merge request cannot merge. |
| `409`       | `SHA does not match HEAD of source branch` | The provided `sha` parameter does not match the HEAD of the source. |
| `422`       | `Branch cannot be merged`                  | The merge request failed to merge. |

For important notes on response data, see [Single merge request response notes](#single-merge-request-response-notes).

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
  "target_branch": "main",
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
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
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

## Merge to default merge ref path

Merge the changes between the merge request source and target branches into `refs/merge-requests/:iid/merge`
ref, of the target project repository, if possible. This ref has the state the target branch would have if
a regular merge action was taken.

This action isn't a regular merge action, because it doesn't change the merge request target branch state in any manner.

This ref (`refs/merge-requests/:iid/merge`) isn't necessarily overwritten when submitting
requests to this API, though it makes sure the ref has the latest possible state.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/merge_ref
```

Supported attributes:

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer           | Yes      | The internal ID of the merge request. |

This API returns specific HTTP status codes:

| HTTP Status | Message                          | Reason |
|-------------|----------------------------------|--------|
| `200`       | _(none)_                         | Success. Returns the HEAD commit of `refs/merge-requests/:iid/merge`. |
| `400`       | `Merge request is not mergeable` | The merge request has conflicts. |
| `400`       | `Merge ref cannot be updated`    |        |
| `400`       | `Unsupported operation`          | The GitLab database is in read-only mode. |

Example response:

```json
{
  "commit_id": "854a3a7a17acbcc0bbbea170986df1eb60435f34"
}
```

## Cancel merge when pipeline succeeds

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/cancel_merge_when_pipeline_succeeds
```

Supported attributes:

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer           | Yes      | The internal ID of the merge request. |

This API returns specific HTTP status codes:

| HTTP Status | Message  | Reason |
|-------------|----------|--------|
| `201`       | _(none)_ | Success, or the merge request has already merged. |
| `406`       | `Can't cancel the automatic merge` | The merge request is closed. |

For important notes on response data, see [Single merge request response notes](#single-merge-request-response-notes).

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
  "target_branch": "main",
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
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
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

## Rebase a merge request

Automatically rebase the `source_branch` of the merge request against its
`target_branch`.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/rebase
```

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer        | Yes      | The internal ID of the merge request. |
| `skip_ci`           | boolean        | No       | Set to `true` to skip creating a CI pipeline. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/76/merge_requests/1/rebase"
```

This API returns specific HTTP status codes:

| HTTP Status | Message                                    | Reason |
|-------------|--------------------------------------------|--------|
| `202`       | *(no message)* | Successfully enqueued. |
| `403`       | `Cannot push to source branch` | You don't have permission to push to the merge request's source branch. |
| `403`       | `Source branch does not exist` | You don't have permission to push to the merge request's source branch. |
| `403`       | `Source branch is protected from force push` | You don't have permission to push to the merge request's source branch. |
| `409`       | `Failed to enqueue the rebase operation` | A long-lived transaction might have blocked your request. |

If the request is added to the queue successfully, the response contains:

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

The [notes](notes.md) resource creates comments.

## List issues that close on merge

Get all the issues that would close by merging the provided merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/closes_issues
```

Supported attributes:

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | Yes   | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer        | Yes      | Internal ID of the merge request. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes when you use the GitLab issue tracker:

| Attribute                   | Type     | Description                                                                                                                       |
|-----------------------------|----------|-----------------------------------------------------------------------------------------------------------------------------------|
| `[].assignee`               | object   | First assignee of the issue.                                                                                                      |
| `[].assignees`              | array    | Assignees of the issue.                                                                                                           |
| `[].author`                 | object   | User who created this issue.                                                                                                      |
| `[].blocking_issues_count`  | integer  | Count of issues this issue is blocking.                                                                                           |
| `[].closed_at`              | datetime | Timestamp of when the issue was closed.                                                                                           |
| `[].closed_by`              | object   | User who closed this issue.                                                                                                       |
| `[].confidential`           | boolean  | Indicates if the issue is confidential.                                                                                           |
| `[].created_at`             | datetime | Timestamp of when the issue was created.                                                                                          |
| `[].description`            | string   | Description of the issue.                                                                                                         |
| `[].discussion_locked`      | boolean  | Indicates if comments on the issue are locked to members only.                                                                    |
| `[].downvotes`              | integer  | Number of downvotes the issue has received.                                                                                       |
| `[].due_date`               | datetime | Due date of the issue.                                                                                                            |
| `[].id`                     | integer  | ID of the issue.                                                                                                                  |
| `[].iid`                    | integer  | Internal ID of the issue.                                                                                                         |
| `[].issue_type`             | string   | Type of the issue. Can be `issue`, `incident`, `test_case`, `requirement`, `task`.                                                |
| `[].labels`                 | array    | Labels of the issue.                                                                                                              |
| `[].merge_requests_count`   | integer  | Number of merge requests that close the issue on merge.                                                                           |
| `[].milestone`              | object   | Milestone of the issue.                                                                                                           |
| `[].project_id`             | integer  | ID of the issue project.                                                                                                          |
| `[].state`                  | string   | State of the issue. Can be `opened` or `closed`.                                                                                  |
| `[].task_completion_status` | object   | Includes `count` and `completed_count`.                                                                                           |
| `[].time_stats`             | object   | Time statistics for the issue. Includes `time_estimate`, `total_time_spent`, `human_time_estimate`, and `human_total_time_spent`. |
| `[].title`                  | string   | Title of the issue.                                                                                                               |
| `[].type`                   | string   | Type of the issue. Same as `issue_type`, but uppercase.                                                                           |
| `[].updated_at`             | datetime | Timestamp of when the issue was updated.                                                                                          |
| `[].upvotes`                | integer  | Number of upvotes the issue has received.                                                                                         |
| `[].user_notes_count`       | integer  | User notes count of the issue.                                                                                                    |
| `[].web_url`                | string   | Web URL of the issue.                                                                                                             |
| `[].weight`                 | integer  | Weight of the issue.                                                                                                              |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes when you use an external issue tracker, like Jira:

| Attribute                   | Type     | Description                                                                                                                       |
|-----------------------------|----------|-----------------------------------------------------------------------------------------------------------------------------------|
| `[].id`                     | integer  | ID of the issue.                                                                                                                  |
| `[].title`                  | string   | Title of the issue.                                                                                                               |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/76/merge_requests/1/closes_issues"
```

Example response when you use the GitLab issue tracker:

```json
[
  {
    "id": 76,
    "iid": 6,
    "project_id": 1,
    "title": "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
    "description": "Ratione dolores corrupti mollitia soluta quia.",
    "state": "opened",
    "created_at": "2024-09-06T10:58:49.002Z",
    "updated_at": "2024-09-06T11:01:40.710Z",
    "closed_at": null,
    "closed_by": null,
    "labels": [
      "label"
    ],
    "milestone": {
      "project_id": 1,
      "description": "Ducimus nam enim ex consequatur cumque ratione.",
      "state": "closed",
      "due_date": null,
      "iid": 2,
      "created_at": "2016-01-04T15:31:39.996Z",
      "title": "v4.0",
      "id": 17,
      "updated_at": "2016-01-04T15:31:39.996Z"
    },
    "assignees": [
      {
        "id": 1,
        "username": "root",
        "name": "Administrator",
        "state": "active",
        "locked": false,
        "avatar_url": null,
        "web_url": "https://gitlab.example.com/root"
      }
    ],
    "author": {
      "id": 18,
      "username": "eileen.lowe",
      "name": "Alexandra Bashirian",
      "state": "active",
      "locked": false,
      "avatar_url": null,
      "web_url": "https://gitlab.example.com/eileen.lowe"
    },
    "type": "ISSUE",
    "assignee": {
      "id": 1,
      "username": "root",
      "name": "Administrator",
      "state": "active",
      "locked": false,
      "avatar_url": null,
      "web_url": "https://gitlab.example.com/root"
    },
    "user_notes_count": 1,
    "merge_requests_count": 1,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "discussion_locked": null,
    "issue_type": "issue",
    "web_url": "https://gitlab.example.com/my-group/my-project/-/issues/6",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "task_completion_status": {
      "count": 0,
      "completed_count": 0
    },
    "weight": null,
    "blocking_issues_count": 0
 }
]
```

Example response when you use an external issue tracker, like Jira:

```json
[
   {
       "id" : "PROJECT-123",
       "title" : "Title of this issue"
   }
]
```

## List issues related to the merge request

Get all the related issues from title, description, commit messages, comments, and discussions of the merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/related_issues
```

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer        | Yes      | The internal ID of the merge request. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/76/merge_requests/1/related_issues"
```

Example response when you use the GitLab issue tracker:

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

Example response when you use an external issue tracker, like Jira:

```json
[
   {
       "id" : "PROJECT-123",
       "title" : "Title of this issue"
   }
]
```

## Subscribe to a merge request

Subscribes the authenticated user to a merge request to receive notification.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/subscribe
```

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer           | Yes      | The internal ID of the merge request. |

If the user is already subscribed to the merge request, the endpoint returns the
status code `HTTP 304 Not Modified`.

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/17/subscribe"
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
  "target_branch": "main",
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
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
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

For important notes on response data, see [Single merge request response notes](#single-merge-request-response-notes).

## Unsubscribe from a merge request

Unsubscribes the authenticated user from a merge request to not receive
notifications from that merge request.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/unsubscribe
```

| Attribute           | Type           | Required | Description |
|---------------------|----------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer        | Yes      | The internal ID of the merge request. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/17/unsubscribe"
```

If the user is not subscribed to the merge request, the endpoint returns the
status code `HTTP 304 Not Modified`.

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
  "target_branch": "main",
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
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
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

For important notes on response data, see [Single merge request response notes](#single-merge-request-response-notes).

## Create a to-do item

Manually creates a to-do item for the current user on a merge request.
If a to-do item already exists for the user on that merge request, this endpoint
returns status code `HTTP 304 Not Modified`.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/todo
```

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer           | Yes      | The internal ID of the merge request. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/27/todo"
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

Get a list of merge request diff versions.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/versions
```

| Attribute           | Type    | Required | Description                           |
|---------------------|---------|----------|---------------------------------------|
| `id`                | String  | Yes      | The ID of the project.                |
| `merge_request_iid` | integer | Yes      | The internal ID of the merge request. |

For an explanation of the SHAs in the response,
see [SHAs in the API response](#shas-in-the-api-response).

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/versions"
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
  "real_size": "1",
  "patch_id_sha": "d504412d5b6e6739647e752aff8e468dde093f2f"
}, {
  "id": 108,
  "head_commit_sha": "3eed087b29835c48015768f839d76e5ea8f07a24",
  "base_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "start_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "created_at": "2016-07-25T14:21:33.028Z",
  "merge_request_id": 105,
  "state": "collected",
  "real_size": "1",
  "patch_id_sha": "72c30d1f0115fc1d2bb0b29b24dc2982cbcdfd32"
}]
```

### SHAs in the API response

| SHA field          | Purpose                                                                             |
|--------------------|-------------------------------------------------------------------------------------|
| `base_commit_sha`  | The merge-base commit SHA between the source branch and the target branches.        |
| `head_commit_sha`  | The HEAD commit of the source branch.                                               |
| `start_commit_sha` | The HEAD commit SHA of the target branch when this version of the diff was created. |

## Get a single merge request diff version

Get a single merge request diff version.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/versions/:version_id
```

Supported attributes:

| Attribute           | Type    | Required | Description                               |
|---------------------|---------|----------|-------------------------------------------|
| `id`                | String  | Yes      | ID of the project.                    |
| `merge_request_iid` | integer | Yes      | Internal ID of the merge request.     |
| `version_id`        | integer | Yes      | ID of the merge request diff version. |
| `unidiff`           | boolean | No       | Present diffs in the [unified diff](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html) format. Default is false. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610) in GitLab 16.5.      |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                     | Type         | Description |
|-------------------------------|--------------|-------------|
| `id`                          | integer      | ID of the merge request diff version. |
| `base_commit_sha`             | string       | Merge-base commit SHA between the source branch and the target branches. |
| `commits`                     | object array | Commits in the merge request diff. |
| `commits[].id`                | string       | ID of the commit. |
| `commits[].short_id`          | string       | Short ID of the commit. |
| `commits[].created_at`        | datetime     | Identical to the `committed_date` field. |
| `commits[].parent_ids`        | array        | IDs of the parent commits. |
| `commits[].title`             | string       | Commit title. |
| `commits[].message`           | string       | Commit message. |
| `commits[].author_name`       | string       | Commit author's name. |
| `commits[].author_email`      | string       | Commit author's email address. |
| `commits[].authored_date`     | datetime     | Commit authored date. |
| `commits[].committer_name`    | string       | Name of the committer. |
| `commits[].committer_email`   | string       | Email address of the committer. |
| `commits[].committed_date`    | datetime     | Commit date. |
| `commits[].trailers`          | object       | Git trailers parsed for the commit. Duplicate keys include the last value only. |
| `commits[].extended_trailers` | object       | Git trailers parsed for the commit. |
| `commits[].web_url`           | string       | Web URL of the merge request. |
| `created_at`                  | datetime     | Creation date and time of the merge request. |
| `diffs`                       | object array | Diffs in the merge request diff version. |
| `diffs[].diff`                | string       | Content of the diff. |
| `diffs[].new_path`            | string       | New path of the file. |
| `diffs[].old_path`            | string       | Old path of the file. |
| `diffs[].a_mode`              | string       | Old file mode of the file. |
| `diffs[].b_mode`              | string       | New file mode of the file. |
| `diffs[].new_file`            | boolean      | Indicates an added file. |
| `diffs[].renamed_file`        | boolean      | Indicates a renamed file. |
| `diffs[].deleted_file`        | boolean      | Indicates a removed file. |
| `diffs[].generated_file`      | boolean      | Indicates if the file is [marked as generated](../user/project/merge_requests/changes.md#collapse-generated-files). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141576) in GitLab 16.9. |
| `head_commit_sha`             | string       | HEAD commit of the source branch. |
| `merge_request_id`            | integer      | ID of the merge request. |
| `patch_id_sha`                | string       | [Patch ID](https://git-scm.com/docs/git-patch-id) for the merge request diff. |
| `real_size`                   | string       | Number of changes in the merge request diff. |
| `start_commit_sha`            | string       | HEAD commit SHA of the target branch when this version of the diff was created. |
| `state`                       | string       | State of the merge request diff. Can be `collected`, `overflow`, `without_files`. Deprecated values: `timeout`, `overflow_commits_safe_size`, `overflow_diff_files_limit`, `overflow_diff_lines_limit`. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/versions/1"
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
  "patch_id_sha": "d504412d5b6e6739647e752aff8e468dde093f2f",
  "commits": [{
    "id": "33e2ee8579fda5bc36accc9c6fbd0b4fefda9e30",
    "short_id": "33e2ee85",
    "parent_ids": [],
    "title": "Change year to 2018",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "authored_date": "2016-07-26T17:44:29.000+03:00",
    "committer_name": "Administrator",
    "committer_email": "admin@example.com",
    "committed_date": "2016-07-26T17:44:29.000+03:00",
    "created_at": "2016-07-26T17:44:29.000+03:00",
    "message": "Change year to 2018",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/project/-/commit/33e2ee8579fda5bc36accc9c6fbd0b4fefda9e30"
  }, {
    "id": "aa24655de48b36335556ac8a3cd8bb521f977cbd",
    "short_id": "aa24655d",
    "parent_ids": [],
    "title": "Update LICENSE",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "authored_date": "2016-07-25T17:21:53.000+03:00",
    "committer_name": "Administrator",
    "committer_email": "admin@example.com",
    "committed_date": "2016-07-25T17:21:53.000+03:00",
    "created_at": "2016-07-25T17:21:53.000+03:00",
    "message": "Update LICENSE",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/project/-/commit/aa24655de48b36335556ac8a3cd8bb521f977cbd"
  }, {
    "id": "3eed087b29835c48015768f839d76e5ea8f07a24",
    "short_id": "3eed087b",
    "parent_ids": [],
    "title": "Add license",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "authored_date": "2016-07-25T17:21:20.000+03:00",
    "committer_name": "Administrator",
    "committer_email": "admin@example.com",
    "committed_date": "2016-07-25T17:21:20.000+03:00",
    "created_at": "2016-07-25T17:21:20.000+03:00",
    "message": "Add license",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/project/-/commit/3eed087b29835c48015768f839d76e5ea8f07a24"
  }],
  "diffs": [{
    "old_path": "LICENSE",
    "new_path": "LICENSE",
    "a_mode": "0",
    "b_mode": "100644",
    "diff": "@@ -0,0 +1,21 @@\n+The MIT License (MIT)\n+\n+Copyright (c) 2018 Administrator\n+\n+Permission is hereby granted, free of charge, to any person obtaining a copy\n+of this software and associated documentation files (the \"Software\"), to deal\n+in the Software without restriction, including without limitation the rights\n+to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\n+copies of the Software, and to permit persons to whom the Software is\n+furnished to do so, subject to the following conditions:\n+\n+The above copyright notice and this permission notice shall be included in all\n+copies or substantial portions of the Software.\n+\n+THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n+IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\n+FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\n+AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\n+LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\n+OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\n+SOFTWARE.\n",
    "new_file": true,
    "renamed_file": false,
    "deleted_file": false,
    "generated_file": false
  }]
}
```

## Set a time estimate for a merge request

Sets an estimated time of work for this merge request.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/time_estimate
```

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer           | Yes      | The internal ID of the merge request. |
| `duration`          | string            | Yes      | The duration in human format, such as `3h30m`. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/time_estimate?duration=3h30m"
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

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer           | Yes      | The internal ID of a project's merge request. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/reset_time_estimate"
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
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer        | Yes      | The internal ID of the merge request. |
| `duration`          | string         | Yes      | The duration in human format, such as `3h30m` |
| `summary`           | string         | No       | A summary of how the time was spent. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/add_spent_time?duration=1h"
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
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer        | Yes      | The internal ID of a project's merge request. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/reset_spent_time"
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

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | integer           | Yes      | The internal ID of the merge request. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/time_stats"
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

For approvals, see [Merge request approvals](merge_request_approvals.md).

## List merge request state events

To track which state was set, who did it, and when it happened, check out
[Resource state events API](resource_state_events.md#merge-requests).

## Troubleshooting

### Empty API fields for new merge requests

When you create a merge request, the `diff_refs` and `changes_count` fields are
initially empty. These fields populate asynchronously after you create the
merge request. For more information, see [issue 386562](https://gitlab.com/gitlab-org/gitlab/-/issues/386562),
and the [related discussion](https://forum.gitlab.com/t/diff-refs-empty-after-mr-is-created/78975)
in the GitLab forums.
