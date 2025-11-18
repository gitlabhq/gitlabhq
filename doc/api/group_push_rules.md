---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Use push rules to control the content and format of Git commits your repository accepts. Set standards for commit messages, and block secrets or credentials from being added accidentally.
title: Group push rules API
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to manage [group push rules](../user/group/access_and_permissions.md#group-push-rules)
for newly created projects in a group.

Prerequisites:

- You must have the Owner role for the group or be an administrator for the instance.

## Get the push rules of a group

Gets the push rules of a group.

```plaintext
GET /groups/:id/push_rule
```

Supported attributes:

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer or string | Yes      | ID of the group or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                         | Type    | Description |
|-----------------------------------|---------|-------------|
| `author_email_regex`              | string  | Allow only commit author emails that match this regular expression. |
| `branch_name_regex`               | string  | Allow only branch names that match this regular expression. |
| `commit_committer_check`          | boolean | If `true`, allows commits from users only if the committer email is one of their own verified emails. |
| `commit_committer_name_check`     | boolean | If `true`, allows commits from users only if the commit author name is consistent with their GitLab account name. |
| `commit_message_negative_regex`   | string  | Reject commit messages matching this regular expression. |
| `commit_message_regex`            | string  | Allow only commit messages that match this regular expression. |
| `created_at`                      | string  | Date and time when the push rule was created. |
| `deny_delete_tag`                 | boolean | If `true`, denies deleting a tag. |
| `file_name_regex`                 | string  | Reject filenames matching this regular expression. |
| `id`                              | integer | The ID of the push rule. |
| `max_file_size`                   | integer | Maximum file size (MB) allowed. |
| `member_check`                    | boolean | If `true`, allows only GitLab users to author commits. |
| `prevent_secrets`                 | boolean | If `true`, rejects files that are likely to contain secrets. |
| `reject_non_dco_commits`          | boolean | If `true`, rejects a commit when it's not DCO certified. |
| `reject_unsigned_commits`         | boolean | If `true`, rejects a commit when it's not signed. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/2/push_rule"
```

Example response when push rules are configured with all settings disabled:

```json
{
  "id": 1,
  "created_at": "2020-08-17T19:09:19.580Z",
  "commit_message_regex": "[a-zA-Z]",
  "commit_message_negative_regex": "[x+]",
  "branch_name_regex": "[a-z]",
  "author_email_regex": "^[A-Za-z0-9.]+@gitlab.com$",
  "file_name_regex": "(exe)$",
  "deny_delete_tag": false,
  "member_check": false,
  "prevent_secrets": false,
  "max_file_size": 0,
  "commit_committer_check": null,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": null,
  "reject_non_dco_commits": null
}
```

If push rules were never configured for the group, returns [`404 Not Found`](rest/troubleshooting.md#status-codes):

```json
{
  "message": "404 Not Found"
}
```

{{< alert type="note" >}}

This differs from the [project push rules API](project_push_rules.md#get-project-push-rules),
which returns HTTP `200 OK` with the literal string `"null"` when no push rules are configured.

{{< /alert >}}

When disabled, some boolean attributes return `null` instead of `false`. For example:

- `commit_committer_check`
- `reject_unsigned_commits`
- `reject_non_dco_commits`

## Add push rules to a group

Adds push rules to the group. Use only if you haven't defined any push rules so far.

```plaintext
POST /groups/:id/push_rule
```

Supported attributes:

<!-- markdownlint-disable MD056 -->

| Attribute                         | Type           | Required | Description |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | integer or string | Yes   | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |
| `author_email_regex`              | string         | No       | Allow only commit author emails that match the regular expression provided in this attribute, for example, `@my-company.com$`. |
| `branch_name_regex`               | string         | No       | Allow only branch names that match the regular expression provided in this attribute, for example, `(feature\|hotfix)\/.*`. |
| `commit_committer_check`          | boolean        | No       | If `true`, allows commits from users only if the committer email is one of their own verified emails. |
| `commit_committer_name_check`     | boolean        | No       | If `true`, allows commits from users only if the commit author name is consistent with their GitLab account name. |
| `commit_message_negative_regex`   | string         | No       | Reject commit messages matching the regular expression provided in this attribute, for example, `ssh\:\/\/`. |
| `commit_message_regex`            | string         | No       | If `true`, allows only commit messages that match the regular expression provided in this attribute, for example, `Fixed \d+\..*`. |
| `deny_delete_tag`                 | boolean        | No       | Deny deleting a tag. |
| `file_name_regex`                 | string         | No       | Reject filenames matching the regular expression provided in this attribute, for example, `(jar\|exe)$`. |
| `max_file_size`                   | integer        | No       | Maximum file size (MB) allowed. |
| `member_check`                    | boolean        | No       | If `true`, allows only GitLab users to author commits. |
| `prevent_secrets`                 | boolean        | No       | If `true`, rejects files that are likely to [contain secrets](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/checks/files_denylist.yml). |
| `reject_non_dco_commits`          | boolean        | No       | If `true`, rejects a commit when it's not DCO certified. |
| `reject_unsigned_commits`         | boolean        | No       | If `true`, rejects a commit when it's not signed. |

<!-- markdownlint-enable MD056 -->

If successful, returns [`201 Created`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                         | Type    | Description |
|-----------------------------------|---------|-------------|
| `author_email_regex`              | string  | Allow only commit author emails that match this regular expression. |
| `branch_name_regex`               | string  | Allow only branch names that match this regular expression. |
| `commit_committer_check`          | boolean | If `true`, allows commits from users only if the committer email is one of their own verified emails. |
| `commit_committer_name_check`     | boolean | If `true`, allows commits from users only if the commit author name is consistent with their GitLab account name. |
| `commit_message_negative_regex`   | string  | Reject commit messages matching this regular expression. |
| `commit_message_regex`            | string  | If `true`, allows only commit messages that match this regular expression. |
| `created_at`                      | string  | Date and time when the push rule was created. |
| `deny_delete_tag`                 | boolean | If `true`, denies deleting a tag. |
| `file_name_regex`                 | string  | Reject filenames matching this regular expression. |
| `id`                              | integer | The ID of the push rule. |
| `max_file_size`                   | integer | Maximum file size (MB) allowed. |
| `member_check`                    | boolean | If `true`, allows only GitLab users to author commits. |
| `prevent_secrets`                 | boolean | If `true`, rejects files that are likely to contain secrets. |
| `reject_non_dco_commits`          | boolean | If `true`, rejects a commit when it's not DCO certified. |
| `reject_unsigned_commits`         | boolean | If `true`, rejects a commit when it's not signed. |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/19/push_rule?prevent_secrets=true"
```

Example response:

```json
{
  "id": 1,
  "created_at": "2020-08-31T15:53:00.073Z",
  "commit_committer_check": false,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": false,
  "reject_non_dco_commits": false,
  "commit_message_regex": "[a-zA-Z]",
  "commit_message_negative_regex": "[x+]",
  "branch_name_regex": null,
  "deny_delete_tag": false,
  "member_check": false,
  "prevent_secrets": true,
  "author_email_regex": "^[A-Za-z0-9.]+@gitlab.com$",
  "file_name_regex": null,
  "max_file_size": 100
}
```

## Edit the push rules of a group

Edits the push rules for the group.

```plaintext
PUT /groups/:id/push_rule
```

Supported attributes:

<!-- markdownlint-disable MD056 -->

| Attribute                         | Type           | Required | Description |
|-----------------------------------|----------------|----------|-------------|
| `id`                              | integer or string | Yes   | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |
| `author_email_regex`              | string         | No       | Allow only commit author emails that match the regular expression provided in this attribute, for example, `@my-company.com$`. |
| `branch_name_regex`               | string         | No       | Allow only branch names that match the regular expression provided in this attribute, for example, `(feature\|hotfix)\/.*`. |
| `commit_committer_check`          | boolean        | No       | If `true`, allows commits from users only if the committer email is one of their own verified emails. |
| `commit_committer_name_check`     | boolean        | No       | If `true`, allows commits from users only if the commit author name is consistent with their GitLab account name. |
| `commit_message_negative_regex`   | string         | No       | Reject commit messages matching the regular expression provided in this attribute, for example, `ssh\:\/\/`. |
| `commit_message_regex`            | string         | No       | If `true`, allows only commit messages that match the regular expression provided in this attribute, for example, `Fixed \d+\..*`. |
| `deny_delete_tag`                 | boolean        | No       | If `true`, denies deleting a tag. |
| `file_name_regex`                 | string         | No       | Reject filenames matching the regular expression provided in this attribute, for example, `(jar\|exe)$`. |
| `max_file_size`                   | integer        | No       | Maximum file size (MB) allowed. |
| `member_check`                    | boolean        | No       | If `true`, allows only GitLab users to author commits. |
| `prevent_secrets`                 | boolean        | No       | If `true`, rejects files that are likely to [contain secrets](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/checks/files_denylist.yml). |
| `reject_non_dco_commits`          | boolean        | No       | If `true`, rejects a commit when it's not DCO certified. |
| `reject_unsigned_commits`         | boolean        | No       | If `true`, rejects a commit when it's not signed. |

<!-- markdownlint-enable MD056 -->

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                         | Type    | Description |
|-----------------------------------|---------|-------------|
| `author_email_regex`              | string  | Allow only commit author emails that match this regular expression. |
| `branch_name_regex`               | string  | Allow only branch names that match this regular expression. |
| `commit_committer_check`          | boolean | If `true`, allows commits from users only if the committer email is one of their own verified emails. |
| `commit_committer_name_check`     | boolean | If `true`, allows commits from users only if the commit author name is consistent with their GitLab account name. |
| `commit_message_negative_regex`   | string  | Reject commit messages matching this regular expression. |
| `commit_message_regex`            | string  | If `true`, allows only commit messages that match this regular expression. |
| `created_at`                      | string  | Date and time when the push rule was created. |
| `deny_delete_tag`                 | boolean | If `true`, denies deleting a tag. |
| `file_name_regex`                 | string  | Reject filenames matching this regular expression. |
| `id`                              | integer | The ID of the push rule. |
| `max_file_size`                   | integer | Maximum file size (MB) allowed. |
| `member_check`                    | boolean | If `true`, allows only GitLab users to author commits. |
| `prevent_secrets`                 | boolean | If `true`, rejects files that are likely to contain secrets. |
| `reject_non_dco_commits`          | boolean | If `true`, rejects a commit when it's not DCO certified. |
| `reject_unsigned_commits`         | boolean | If `true`, rejects a commit when it's not signed. |

Example request:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/19/push_rule?member_check=true"
```

Example response:

```json
{
  "id": 19,
  "created_at": "2020-08-31T15:53:00.073Z",
  "commit_committer_check": false,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": false,
  "reject_non_dco_commits": false,
  "commit_message_regex": "[a-zA-Z]",
  "commit_message_negative_regex": "[x+]",
  "branch_name_regex": null,
  "deny_delete_tag": false,
  "member_check": true,
  "prevent_secrets": false,
  "author_email_regex": "^[A-Za-z0-9.]+@staging.gitlab.com$",
  "file_name_regex": null,
  "max_file_size": 100
}
```

## Delete the push rules of a group

Deletes all the push rules of a group.

```plaintext
DELETE /groups/:id/push_rule
```

Supported attributes:

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |

If successful, returns [`204 No Content`](rest/troubleshooting.md#status-codes) with no response body.

Example request:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/19/push_rule"
```
