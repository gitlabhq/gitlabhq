---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Project push rules API
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can manage [push rules](../user/project/repository/push_rules.md) for projects by using the REST API.

## Get project push rules

Get the push rules of a project.

```plaintext
GET /projects/:id/push_rule
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |

Example response:

```json
{
  "id": 1,
  "project_id": 3,
  "commit_message_regex": "Fixes \\d+\\..*",
  "commit_message_negative_regex": "ssh\\:\\/\\/",
  "branch_name_regex": "",
  "deny_delete_tag": false,
  "created_at": "2012-10-12T17:04:47Z",
  "member_check": false,
  "prevent_secrets": false,
  "author_email_regex": "",
  "file_name_regex": "",
  "max_file_size": 5,
  "commit_committer_check": false,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": false,
  "reject_non_dco_commits": false
}
```

## Add a project push rule

Add a push rule to a specified project.

```plaintext
POST /projects/:id/push_rule
```

Supported attributes:

| Attribute                       | Type              | Required | Description |
|:--------------------------------|:------------------|:---------|:------------|
| `id`                            | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `author_email_regex`            | string            | No       | All commit author emails must match this regular expression. |
| `branch_name_regex`             | string            | No       | All branch names must match this regular expression. |
| `commit_message_negative_regex` | string            | No       | No commit message is allowed to match this regular expression. |
| `commit_message_regex`          | string            | No       | All commit messages must match this regular expression. |
| `deny_delete_tag`               | boolean           | No       | Deny deleting a tag. |
| `file_name_regex`               | string            | No       | All committed filenames must **not** match this regular expression. |
| `max_file_size`                 | integer           | No       | Maximum file size (MB). |
| `member_check`                  | boolean           | No       | Restrict commits by author (email) to existing GitLab users. |
| `prevent_secrets`               | boolean           | No       | GitLab rejects any files that are likely to contain secrets. |
| `commit_committer_check`        | boolean           | No       | Users can only push commits to this repository if the committer email is one of their own verified emails. |
| `commit_committer_name_check`   | boolean           | No       | Users can only push commits to this repository if the commit author name is consistent with their GitLab account name. |
| `reject_unsigned_commits`       | boolean           | No       | Reject commit when it's not signed. |
| `reject_non_dco_commits`        | boolean           | No       | Reject commit when it's not DCO certified. |

## Edit project push rule

Edit a push rule for a specified project.

```plaintext
PUT /projects/:id/push_rule
```

Supported attributes:

| Attribute                       | Type              | Required | Description |
|:--------------------------------|:------------------|:---------|:------------|
| `id`                            | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `author_email_regex`            | string            | No       | All commit author emails must match this regular expression. |
| `branch_name_regex`             | string            | No       | All branch names must match this regular expression. |
| `commit_message_negative_regex` | string            | No       | No commit message is allowed to match this regular expression. |
| `commit_message_regex`          | string            | No       | All commit messages must match this regular expression. |
| `deny_delete_tag`               | boolean           | No       | Deny deleting a tag. |
| `file_name_regex`               | string            | No       | All committed filenames must **not** match this regular expression. |
| `max_file_size`                 | integer           | No       | Maximum file size (MB). |
| `member_check`                  | boolean           | No       | Restrict commits by author (email) to existing GitLab users. |
| `prevent_secrets`               | boolean           | No       | GitLab rejects any files that are likely to contain secrets. |
| `commit_committer_check`        | boolean           | No       | Users can only push commits to this repository if the committer email is one of their own verified emails. |
| `commit_committer_name_check`   | boolean           | No       | Users can only push commits to this repository if the commit author name is consistent with their GitLab account name. |
| `reject_unsigned_commits`       | boolean           | No       | Reject commits when they are not signed. |
| `reject_non_dco_commits`        | boolean           | No       | Reject commit when it's not DCO certified. |

## Delete project push rule

Delete a push rule from a project.

```plaintext
DELETE /projects/:id/push_rule
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
