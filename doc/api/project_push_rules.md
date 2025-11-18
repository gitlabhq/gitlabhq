---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project push rules API
description: Manage project push rules to enforce commit standards, validate messages, prevent secrets, and control repository operations.
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to manage project [push rules](../user/project/repository/push_rules.md).

{{< alert type="note" >}}

GitLab uses [RE2 syntax](https://github.com/google/re2/wiki/Syntax) for all regular expressions in push rules.

{{< /alert >}}

## Get project push rules

Get the push rules of a project.

```plaintext
GET /projects/:id/push_rule
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                       | Type    | Description |
|---------------------------------|---------|-------------|
| `author_email_regex`            | string  | All commit author emails must match this regular expression. |
| `branch_name_regex`             | string  | All branch names must match this regular expression. |
| `commit_committer_check`        | boolean | If `true`, users can only push commits to this repository if the committer email is one of their own verified emails. |
| `commit_committer_name_check`   | boolean | If `true`, users can only push commits to this repository if the commit author name is consistent with their GitLab account name. |
| `commit_message_negative_regex` | string  | No commit message is allowed to match this regular expression. |
| `commit_message_regex`          | string  | All commit messages must match this regular expression. |
| `created_at`                    | string  | Date and time when the push rule was created. |
| `deny_delete_tag`               | boolean | If `true`, denies deleting a tag. |
| `file_name_regex`               | string  | All committed filenames must not match this regular expression. |
| `id`                            | integer | ID of the push rule. |
| `max_file_size`                 | integer | Maximum file size (MB). |
| `member_check`                  | boolean | If `true`, restricts commits by author (email) to existing GitLab users. |
| `prevent_secrets`               | boolean | If `true`, GitLab rejects any files that are likely to contain secrets. |
| `project_id`                    | integer | ID of the project. |
| `reject_non_dco_commits`        | boolean | If `true`, rejects commits when not DCO certified. |
| `reject_unsigned_commits`       | boolean | If `true`, rejects commits when not signed. |

If push rules were never configured for the project, returns HTTP `200 OK` with the literal string
`"null"` as the response body.

{{< alert type="note" >}}

This differs from the [group push rules API](group_push_rules.md#get-the-push-rules-of-a-group),
which returns `404 Not Found` error.

{{< /alert >}}

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/3/push_rule"
```

Example response when push rules are configured with all settings disabled:

```json
{
  "id": 1,
  "project_id": 3,
  "created_at": "2012-10-12T17:04:47Z",
  "commit_message_regex": "Fixes \\d+\\..*",
  "commit_message_negative_regex": "ssh\\:\\/\\/",
  "branch_name_regex": "",
  "deny_delete_tag": false,
  "member_check": false,
  "prevent_secrets": false,
  "author_email_regex": "",
  "file_name_regex": "",
  "max_file_size": 0,
  "commit_committer_check": null,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": null,
  "reject_non_dco_commits": null
}
```

If the following attributes are disabled, they return `null` instead of `false`:

- `commit_committer_check`
- `reject_unsigned_commits`
- `reject_non_dco_commits`

Example response when push rules were never configured for the project:

```plaintext
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 4

null
```

This returns the literal string `"null"` (4 characters), not a JSON `null` value.

## Add a project push rule

Add a push rule to a specified project.

```plaintext
POST /projects/:id/push_rule
```

Supported attributes:

| Attribute                       | Type              | Required | Description |
|---------------------------------|-------------------|----------|-------------|
| `id`                            | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `author_email_regex`            | string            | No       | All commit author emails must match this regular expression. |
| `branch_name_regex`             | string            | No       | All branch names must match this regular expression. |
| `commit_committer_check`        | boolean           | No       | If `true`, users can only push commits to this repository if the committer email is one of their own verified emails. |
| `commit_committer_name_check`   | boolean           | No       | If `true`, users can only push commits to this repository if the commit author name is consistent with their GitLab account name. |
| `commit_message_negative_regex` | string            | No       | No commit message is allowed to match this regular expression. |
| `commit_message_regex`          | string            | No       | All commit messages must match this regular expression. |
| `deny_delete_tag`               | boolean           | No       | If `true`, denies deleting a tag. |
| `file_name_regex`               | string            | No       | All committed filenames must not match this regular expression. |
| `max_file_size`                 | integer           | No       | Maximum file size (MB). |
| `member_check`                  | boolean           | No       | If `true`, restricts commits by author (email) to existing GitLab users. |
| `prevent_secrets`               | boolean           | No       | If `true`, GitLab rejects any files that are likely to contain secrets. |
| `reject_non_dco_commits`        | boolean           | No       | If `true`, rejects commits when not DCO certified. |
| `reject_unsigned_commits`       | boolean           | No       | If `true`, rejects commits when not signed. |

If successful, returns [`201 Created`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                       | Type    | Description |
|---------------------------------|---------|-------------|
| `author_email_regex`            | string  | All commit author emails must match this regular expression. |
| `branch_name_regex`             | string  | All branch names must match this regular expression. |
| `commit_committer_check`        | boolean | If `true`, users can only push commits to this repository if the committer email is one of their own verified emails. |
| `commit_committer_name_check`   | boolean | If `true`, users can only push commits to this repository if the commit author name is consistent with their GitLab account name. |
| `commit_message_negative_regex` | string  | No commit message is allowed to match this regular expression. |
| `commit_message_regex`          | string  | All commit messages must match this regular expression. |
| `created_at`                    | string  | Date and time when the push rule was created. |
| `deny_delete_tag`               | boolean | If `true`, denies deleting a tag. |
| `file_name_regex`               | string  | All committed filenames must not match this regular expression. |
| `id`                            | integer | ID of the push rule. |
| `max_file_size`                 | integer | Maximum file size (MB). |
| `member_check`                  | boolean | If `true`, restricts commits by author (email) to existing GitLab users. |
| `prevent_secrets`               | boolean | If `true`, GitLab rejects any files that are likely to contain secrets. |
| `project_id`                    | integer | ID of the project. |
| `reject_non_dco_commits`        | boolean | If `true`, rejects commits when not DCO certified. |
| `reject_unsigned_commits`       | boolean | If `true`, rejects commits when not signed. |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/3/push_rule" \
  --data "commit_message_regex=Fixes \\d+\\..*" \
  --data "deny_delete_tag=false"
```

Example response:

```json
{
  "id": 1,
  "project_id": 3,
  "created_at": "2012-10-12T17:04:47Z",
  "commit_message_regex": "Fixes \\d+\\..*",
  "commit_message_negative_regex": "",
  "branch_name_regex": "",
  "deny_delete_tag": false,
  "member_check": false,
  "prevent_secrets": false,
  "author_email_regex": "",
  "file_name_regex": "",
  "max_file_size": 0,
  "commit_committer_check": false,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": false,
  "reject_non_dco_commits": false
}
```

## Edit project push rule

Edit a push rule for a specified project.

```plaintext
PUT /projects/:id/push_rule
```

Supported attributes:

| Attribute                       | Type              | Required | Description |
|---------------------------------|-------------------|----------|-------------|
| `id`                            | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `author_email_regex`            | string            | No       | All commit author emails must match this regular expression. |
| `branch_name_regex`             | string            | No       | All branch names must match this regular expression. |
| `commit_committer_check`        | boolean           | No       | If `true`, users can only push commits to this repository if the committer email is one of their own verified emails. |
| `commit_committer_name_check`   | boolean           | No       | If `true`, users can only push commits to this repository if the commit author name is consistent with their GitLab account name. |
| `commit_message_negative_regex` | string            | No       | No commit message is allowed to match this regular expression. |
| `commit_message_regex`          | string            | No       | All commit messages must match this regular expression. |
| `deny_delete_tag`               | boolean           | No       | If `true`, denies deleting a tag. |
| `file_name_regex`               | string            | No       | All committed filenames must not match this regular expression. |
| `max_file_size`                 | integer           | No       | Maximum file size (MB). |
| `member_check`                  | boolean           | No       | If `true`, restricts commits by author (email) to existing GitLab users. |
| `prevent_secrets`               | boolean           | No       | If `true`, GitLab rejects any files that are likely to contain secrets. |
| `reject_non_dco_commits`        | boolean           | No       | If `true`, rejects commits when not DCO certified. |
| `reject_unsigned_commits`       | boolean           | No       | If `true`, rejects commits when not signed. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                       | Type    | Description |
|---------------------------------|---------|-------------|
| `author_email_regex`            | string  | All commit author emails must match this regular expression. |
| `branch_name_regex`             | string  | All branch names must match this regular expression. |
| `commit_committer_check`        | boolean | If `true`, users can only push commits to this repository if the committer email is one of their own verified emails. |
| `commit_committer_name_check`   | boolean | If `true`, users can only push commits to this repository if the commit author name is consistent with their GitLab account name. |
| `commit_message_negative_regex` | string  | No commit message is allowed to match this regular expression. |
| `commit_message_regex`          | string  | All commit messages must match this regular expression. |
| `created_at`                    | string  | Date and time when the push rule was created. |
| `deny_delete_tag`               | boolean | If `true`, denies deleting a tag. |
| `file_name_regex`               | string  | All committed filenames must not match this regular expression. |
| `id`                            | integer | ID of the push rule. |
| `max_file_size`                 | integer | Maximum file size (MB). |
| `member_check`                  | boolean | If `true`, restricts commits by author (email) to existing GitLab users. |
| `prevent_secrets`               | boolean | If `true`, GitLab rejects any files that are likely to contain secrets. |
| `project_id`                    | integer | ID of the project. |
| `reject_non_dco_commits`        | boolean | If `true`, rejects commits when not DCO certified. |
| `reject_unsigned_commits`       | boolean | If `true`, rejects commits when not signed. |

Example request:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/3/push_rule" \
  --data "commit_message_regex=Fixes \\d+\\..*" \
  --data "deny_delete_tag=true"
```

Example response:

```json
{
  "id": 1,
  "project_id": 3,
  "created_at": "2012-10-12T17:04:47Z",
  "commit_message_regex": "Fixes \\d+\\..*",
  "commit_message_negative_regex": "",
  "branch_name_regex": "",
  "deny_delete_tag": true,
  "member_check": false,
  "prevent_secrets": false,
  "author_email_regex": "",
  "file_name_regex": "",
  "max_file_size": 0,
  "commit_committer_check": false,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": false,
  "reject_non_dco_commits": false
}
```

## Delete project push rule

Delete a push rule from a project.

```plaintext
DELETE /projects/:id/push_rule
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

If successful, returns [`204 No Content`](rest/troubleshooting.md#status-codes).

Example request:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/3/push_rule"
```
