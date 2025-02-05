---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Documentation for the REST API for merge request approval settings in GitLab."
title: Merge request approval settings API
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Configuration for
[approval settings on all merge requests](../user/project/merge_requests/approvals/settings.md)
in a group or project. All endpoints require authentication.

## Group MR approval settings

Prerequisites:

- You must have the Owner role in the group.

### Get group MR approval settings

Get the merge request approval settings of a group.

```plaintext
GET /groups/:id/merge_request_approval_setting
```

Parameters:

| Attribute        | Type           | Required | Description |
|:-----------------|:---------------|:---------|:------------|
| `id`             | integer or string | Yes      | ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/merge_request_approval_setting"
```

Example response:

```json
{
  "allow_author_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_committer_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_overrides_to_approver_list_per_merge_request": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "retain_approvals_on_push": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "selective_code_owner_removals": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_password_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_reauthentication_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  }
}
```

### Update group MR approval settings

Update the merge request approval settings of a group.

```plaintext
PUT /groups/:id/merge_request_approval_setting
```

Parameters:

| Attribute                                            | Type              | Required | Description |
|------------------------------------------------------|-------------------|----------|-------------|
| `id`                                                 | integer or string | Yes      | ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `allow_author_approval`                              | boolean           | No       | Allow or prevent authors from self approving merge requests; `true` means authors can self approve. |
| `allow_committer_approval`                           | boolean           | No       | Allow or prevent committers from self approving merge requests. |
| `allow_overrides_to_approver_list_per_merge_request` | boolean           | No       | Allow or prevent overriding approvers per merge request. |
| `retain_approvals_on_push`                           | boolean           | No       | Retain approval count on a new push. |
| `selective_code_owner_removals`                      | boolean           | No       | Reset approvals from Code Owners if their files changed. You must disable the `retain_approvals_on_push` field to use this field. |
| `require_reauthentication_to_approve`                | boolean           | No       | Require approver to authenticate before adding the approval. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/431346) in GitLab 17.1. |

Example request:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/merge_request_approval_setting?allow_author_approval=false"
```

Example response:

```json
{
  "allow_author_approval": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "allow_committer_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_overrides_to_approver_list_per_merge_request": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "retain_approvals_on_push": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "selective_code_owner_removals": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_password_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_reauthentication_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  }
}
```

## Project MR approval settings

Prerequisites:

- You must have the Maintainer role in the project.

### Get project MR approval settings

Get the merge request approval settings of a project.

```plaintext
GET /projects/:id/merge_request_approval_setting
```

Parameters:

| Attribute        | Type           | Required | Description |
|:-----------------|:---------------|:---------|:------------|
| `id`             | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/merge_request_approval_setting"
```

Example response:

```json
{
  "allow_author_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_committer_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_overrides_to_approver_list_per_merge_request": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "retain_approvals_on_push": {
    "value": false,
    "locked": true,
    "inherited_from": "group"
  },
  "selective_code_owner_removals": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_password_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_reauthentication_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  }
}
```

### Update project MR approval settings

Update the merge request approval settings of a project.

```plaintext
PUT /projects/:id/merge_request_approval_setting
```

Parameters:

| Attribute                                            | Type              | Required | Description |
|------------------------------------------------------|-------------------|----------|-------------|
| `id`                                                 | integer or string | Yes      | ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `allow_author_approval`                              | boolean           | No       | Allow or prevent authors from self approving merge requests; `true` means authors can self approve. |
| `allow_committer_approval`                           | boolean           | No       | Allow or prevent committers from self approving merge requests. |
| `allow_overrides_to_approver_list_per_merge_request` | boolean           | No       | Allow or prevent overriding approvers per merge request. |
| `retain_approvals_on_push`                           | boolean           | No       | Retain approval count on a new push. |
| `selective_code_owner_removals`                      | boolean           | No       | Reset approvals from Code Owners if their files changed. You must disable the `retain_approvals_on_push` field to use this field. |
| `require_reauthentication_to_approve`                | boolean           | No       | Require approver to authenticate before adding the approval. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/431346) in GitLab 17.1. |

Example request:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/merge_request_approval_setting?allow_author_approval=false"
```

Example response:

```json
{
  "allow_author_approval": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "allow_committer_approval": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "allow_overrides_to_approver_list_per_merge_request": {
    "value": true,
    "locked": false,
    "inherited_from": null
  },
  "retain_approvals_on_push": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "selective_code_owner_removals": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_password_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  },
  "require_reauthentication_to_approve": {
    "value": false,
    "locked": false,
    "inherited_from": null
  }
}
```
