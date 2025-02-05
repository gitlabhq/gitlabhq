---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Use push rules to control the content and format of Git commits your repository will accept. Set standards for commit messages, and block secrets or credentials from being added accidentally."
title: Group push rules API
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The following [push rules](../user/group/access_and_permissions.md#group-push-rules)
endpoints are only available to group owners and administrators.

## Get the push rules of a group

Gets the push rules of a group.

```plaintext
GET /groups/:id/push_rule
```

Supported attributes:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID of the group or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/2/push_rule"
```

Example response:

```json
{
  "id": 1,
  "created_at": "2020-08-17T19:09:19.580Z",
  "commit_committer_check": true,
  "commit_committer_name_check": true,
  "reject_unsigned_commits": false,
  "reject_non_dco_commits": false,
  "commit_message_regex": "[a-zA-Z]",
  "commit_message_negative_regex": "[x+]",
  "branch_name_regex": "[a-z]",
  "deny_delete_tag": true,
  "member_check": true,
  "prevent_secrets": true,
  "author_email_regex": "^[A-Za-z0-9.]+@gitlab.com$",
  "file_name_regex": "(exe)$",
  "max_file_size": 100
}
```

## Add push rules to a group

Adds push rules to the group. Use only if you haven't defined any push rules so far.

```plaintext
POST /groups/:id/push_rule
```

Supported attributes:

<!-- markdownlint-disable MD056 -->

| Attribute                                     | Type           | Required | Description |
| --------------------------------------------- | -------------- | -------- | ----------- |
| `id`                                          | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `deny_delete_tag`                             | boolean        | no       | Deny deleting a tag. |
| `member_check`                                | boolean        | no       | Allow only GitLab users to author commits. |
| `prevent_secrets`                             | boolean        | no       | Reject files that are likely to [contain secrets](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/checks/files_denylist.yml). |
| `commit_message_regex`                        | string         | no       | Allow only commit messages that match the regular expression provided in this attribute, for example, `Fixed \d+\..*`. |
| `commit_message_negative_regex`               | string         | no       | Reject commit messages matching the regular expression provided in this attribute, for example, `ssh\:\/\/`. |
| `branch_name_regex`                           | string         | no       | Allow only branch names that match the regular expression provided in this attribute, for example, `(feature|hotfix)\/.*`. |
| `author_email_regex`                          | string         | no       | Allow only commit author emails that match the regular expression provided in this attribute, for example, `@my-company.com$`. |
| `file_name_regex`                             | string         | no       | Reject filenames matching the regular expression provided in this attribute, for example, `(jar|exe)$`. |
| `max_file_size`                               | integer        | no       | Maximum file size (MB) allowed. |
| `commit_committer_check`                      | boolean        | no       | Allow commits from users only if the committer email is one of their own verified emails. |
| `commit_committer_name_check`                 | boolean        | no       | Allow commits from users only if the commit author name is consistent with their GitLab account name. |
| `reject_unsigned_commits`                     | boolean        | no       | Reject a commit when it's not signed. |
| `reject_non_dco_commits`                      | boolean        | no       | Reject a commit when it's not DCO certified. |

<!-- markdownlint-enable MD056 -->

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

<!-- markdownlint-disable MD056 -->

| Attribute                                     | Type           | Required | Description |
| --------------------------------------------- | -------------- | -------- | ----------- |
| `id`                                          | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `deny_delete_tag`                             | boolean        | no       | Deny deleting a tag. |
| `member_check`                                | boolean        | no       | Allow only GitLab users to author commits. |
| `prevent_secrets`                             | boolean        | no       | Reject files that are likely to [contain secrets](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/checks/files_denylist.yml). |
| `commit_message_regex`                        | string         | no       | Allow only commit messages that match the regular expression provided in this attribute, for example, `Fixed \d+\..*`. |
| `commit_message_negative_regex`               | string         | no       | Reject commit messages matching the regular expression provided in this attribute, for example, `ssh\:\/\/`. |
| `branch_name_regex`                           | string         | no       | Allow only branch names that match the regular expression provided in this attribute, for example, `(feature|hotfix)\/.*`. |
| `author_email_regex`                          | string         | no       | Allow only commit author emails that match the regular expression provided in this attribute, for example, `@my-company.com$`. |
| `file_name_regex`                             | string         | no       | Reject filenames matching the regular expression provided in this attribute, for example, `(jar|exe)$`. |
| `max_file_size`                               | integer        | no       | Maximum file size (MB) allowed. |
| `commit_committer_check`                      | boolean        | no       | Allow commits from users only if the committer email is one of their own verified emails. |
| `commit_committer_name_check`                 | boolean        | no       | Allow commits from users only if the commit author name is consistent with their GitLab account name. |
| `reject_unsigned_commits`                     | boolean        | no       | Reject a commit when it's not signed. |
| `reject_non_dco_commits`                      | boolean        | no       | Reject a commit when it's not DCO certified. |

<!-- markdownlint-enable MD056 -->

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

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/19/push_rule"
```

If successful, no response is returned.
