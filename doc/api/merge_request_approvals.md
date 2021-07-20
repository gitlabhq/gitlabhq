---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, api
---

# Merge request approvals API **(PREMIUM)**

Configuration for
[approvals on all merge requests](../user/project/merge_requests/approvals/index.md)
in the project. Must be authenticated for all endpoints.

## Project-level MR approvals

### Get Configuration

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/183) in GitLab 10.6.
> - Moved to GitLab Premium in 13.9.

You can request information about a project's approval configuration using the
following endpoint:

```plaintext
GET /projects/:id/approvals
```

**Parameters:**

| Attribute | Type    | Required | Description         |
| --------- | ------- | -------- | ------------------- |
| `id`      | integer or string | yes      | The ID or [URL-encoded path of a project](index.md#namespaced-path-encoding) |

```json
{
  "approvals_before_merge": 2,
  "reset_approvals_on_push": true,
  "disable_overriding_approvers_per_merge_request": false,
  "merge_requests_author_approval": true,
  "merge_requests_disable_committers_approval": false,
  "require_password_to_approve": true
}
```

### Change configuration

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/183) in GitLab 10.6.
> - Moved to GitLab Premium in 13.9.

If you are allowed to, you can change approval configuration using the following
endpoint:

```plaintext
POST /projects/:id/approvals
```

**Parameters:**

| Attribute                                        | Type    | Required | Description                                                                                         |
| ------------------------------------------------ | ------- | -------- | --------------------------------------------------------------------------------------------------- |
| `id`                                             | integer or string | yes      | The ID or [URL-encoded path of a project](index.md#namespaced-path-encoding)  |
| `approvals_before_merge`                         | integer | no       | How many approvals are required before an MR can be merged. Deprecated in 12.0 in favor of Approval Rules API. |
| `reset_approvals_on_push`                        | boolean | no       | Reset approvals on a new push                                                                       |
| `disable_overriding_approvers_per_merge_request` | boolean | no       | Allow/Disallow overriding approvers per MR                                                          |
| `merge_requests_author_approval`                 | boolean | no       | Allow/Disallow authors from self approving merge requests; `true` means authors can self approve |
| `merge_requests_disable_committers_approval`     | boolean | no       | Allow/Disallow committers from self approving merge requests                                        |
| `require_password_to_approve`                    | boolean | no       | Require approver to enter a password to authenticate before adding the approval         |

```json
{
  "approvals_before_merge": 2,
  "reset_approvals_on_push": true,
  "disable_overriding_approvers_per_merge_request": false,
  "merge_requests_author_approval": false,
  "merge_requests_disable_committers_approval": false,
  "require_password_to_approve": true
}
```

### Get project-level rules

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11877) in GitLab 12.3.
> - Moved to GitLab Premium in 13.9.
> - `protected_branches` property was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.7.

You can request information about a project's approval rules using the following endpoint:

```plaintext
GET /projects/:id/approval_rules
```

**Parameters:**

| Attribute            | Type    | Required | Description                                               |
|----------------------|---------|----------|-----------------------------------------------------------|
| `id`                 | integer or string | yes      | The ID or [URL-encoded path of a project](index.md#namespaced-path-encoding) |

```json
[
  {
    "id": 1,
    "name": "security",
    "rule_type": "regular",
    "eligible_approvers": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      },
      {
        "id": 50,
        "name": "Group Member 1",
        "username": "group_member_1",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/group_member_1"
      }
    ],
    "approvals_required": 3,
    "users": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      }
    ],
    "groups": [
      {
        "id": 5,
        "name": "group1",
        "path": "group1",
        "description": "",
        "visibility": "public",
        "lfs_enabled": false,
        "avatar_url": null,
        "web_url": "http://localhost/groups/group1",
        "request_access_enabled": false,
        "full_name": "group1",
        "full_path": "group1",
        "parent_id": null,
        "ldap_cn": null,
        "ldap_access": null
      }
    ],
    "protected_branches": [
      {
        "id": 1,
        "name": "master",
        "push_access_levels": [
          {
            "access_level": 30,
            "access_level_description": "Developers + Maintainers"
          }
        ],
        "merge_access_levels": [
          {
            "access_level": 30,
            "access_level_description": "Developers + Maintainers"
          }
        ],
        "unprotect_access_levels": [
          {
            "access_level": 40,
            "access_level_description": "Maintainers"
          }
        ],
        "code_owner_approval_required": "false"
      }
    ],
    "contains_hidden_groups": false
  }
]
```

### Get a single project-level rule

> - Introduced 13.7.

You can request information about a single project approval rules using the following endpoint:

```plaintext
GET /projects/:id/approval_rules/:approval_rule_id
```

**Parameters:**

| Attribute            | Type    | Required | Description                                               |
|----------------------|---------|----------|-----------------------------------------------------------|
| `id`                 | integer or string | yes      | The ID or [URL-encoded path of a project](index.md#namespaced-path-encoding) |
| `approval_rule_id`   | integer | yes      | The ID of a approval rule                                 |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "eligible_approvers": [
    {
      "id": 5,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 3,
  "users": [
    {
      "id": 5,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "protected_branches": [
    {
      "id": 1,
      "name": "master",
      "push_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "merge_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "unprotect_access_levels": [
        {
          "access_level": 40,
          "access_level_description": "Maintainers"
        }
      ],
      "code_owner_approval_required": "false"
    }
  ],
  "contains_hidden_groups": false
}
```

### Create project-level rule

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11877) in GitLab 12.3.
> - Moved to GitLab Premium in 13.9.

You can create project approval rules using the following endpoint:

```plaintext
POST /projects/:id/approval_rules
```

**Parameters:**

| Attribute              | Type    | Required | Description                                                      |
|------------------------|---------|----------|------------------------------------------------------------------|
| `id`                   | integer or string | yes      | The ID or [URL-encoded path of a project](index.md#namespaced-path-encoding) |
| `name`                 | string  | yes      | The name of the approval rule                                    |
| `approvals_required`   | integer | yes      | The number of required approvals for this rule                   |
| `user_ids`             | Array   | no       | The ids of users as approvers                                    |
| `group_ids`            | Array   | no       | The ids of groups as approvers                                   |
| `protected_branch_ids` | Array   | no       | **(PREMIUM)** The ids of protected branches to scope the rule by |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "eligible_approvers": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 1,
  "users": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "protected_branches": [
    {
      "id": 1,
      "name": "master",
      "push_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "merge_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "unprotect_access_levels": [
        {
          "access_level": 40,
          "access_level_description": "Maintainers"
        }
      ],
      "code_owner_approval_required": "false"
    }
  ],
  "contains_hidden_groups": false
}
```

### Update project-level rule

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11877) in GitLab 12.3.
> - Moved to GitLab Premium in 13.9.

You can update project approval rules using the following endpoint:

```plaintext
PUT /projects/:id/approval_rules/:approval_rule_id
```

**Important:** Approvers and groups not in the `users`/`groups` parameters are **removed**

**Parameters:**

| Attribute              | Type    | Required | Description                                                      |
|------------------------|---------|----------|------------------------------------------------------------------|
| `id`                   | integer or string | yes      | The ID or [URL-encoded path of a project](index.md#namespaced-path-encoding) |
| `approval_rule_id`     | integer | yes      | The ID of a approval rule                                        |
| `name`                 | string  | yes      | The name of the approval rule                                    |
| `approvals_required`   | integer | yes      | The number of required approvals for this rule                   |
| `user_ids`             | Array   | no       | The ids of users as approvers                                    |
| `group_ids`            | Array   | no       | The ids of groups as approvers                                   |
| `protected_branch_ids` | Array   | no       | **(PREMIUM)** The ids of protected branches to scope the rule by |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "eligible_approvers": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 1,
  "users": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "protected_branches": [
    {
      "id": 1,
      "name": "master",
      "push_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "merge_access_levels": [
        {
          "access_level": 30,
          "access_level_description": "Developers + Maintainers"
        }
      ],
      "unprotect_access_levels": [
        {
          "access_level": 40,
          "access_level_description": "Maintainers"
        }
      ],
      "code_owner_approval_required": "false"
    }
  ],
  "contains_hidden_groups": false
}
```

### Delete project-level rule

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11877) in GitLab 12.3.
> - Moved to GitLab Premium in 13.9.

You can delete project approval rules using the following endpoint:

```plaintext
DELETE /projects/:id/approval_rules/:approval_rule_id
```

**Parameters:**

| Attribute            | Type    | Required | Description                                               |
|----------------------|---------|----------|-----------------------------------------------------------|
| `id`                 | integer or string | yes      | The ID or [URL-encoded path of a project](index.md#namespaced-path-encoding) |
| `approval_rule_id`   | integer | yes      | The ID of a approval rule

## Merge Request-level MR approvals

Configuration for approvals on a specific Merge Request. Must be authenticated for all endpoints.

### Get Configuration

> - Introduced in GitLab 8.9.
> - Moved to GitLab Premium in 13.9.

You can request information about a merge request's approval status using the
following endpoint:

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/approvals
```

**Parameters:**

| Attribute           | Type    | Required | Description         |
|---------------------|---------|----------|---------------------|
| `id`                | integer or string | yes      | The ID or [URL-encoded path of a project](index.md#namespaced-path-encoding) |
| `merge_request_iid` | integer | yes      | The IID of MR       |

```json
{
  "id": 5,
  "iid": 5,
  "project_id": 1,
  "title": "Approvals API",
  "description": "Test",
  "state": "opened",
  "created_at": "2016-06-08T00:19:52.638Z",
  "updated_at": "2016-06-08T21:20:42.470Z",
  "merge_status": "cannot_be_merged",
  "approvals_required": 2,
  "approvals_left": 1,
  "approved_by": [
    {
      "user": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
        "web_url": "http://localhost:3000/root"
      }
    }
  ]
}
```

### Change approval configuration

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/183) in GitLab 10.6.
> - Moved to GitLab Premium in 13.9.

If you are allowed to, you can change `approvals_required` using the following
endpoint:

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/approvals
```

**Parameters:**

| Attribute            | Type    | Required | Description                                |
|----------------------|---------|----------|--------------------------------------------|
| `id`                 | integer or string | yes      | The ID or [URL-encoded path of a project](index.md#namespaced-path-encoding) |
| `merge_request_iid`  | integer | yes      | The IID of MR                              |
| `approvals_required` | integer | yes      | Approvals required before MR can be merged. Deprecated in 12.0 in favor of Approval Rules API. |

```json
{
  "id": 5,
  "iid": 5,
  "project_id": 1,
  "title": "Approvals API",
  "description": "Test",
  "state": "opened",
  "created_at": "2016-06-08T00:19:52.638Z",
  "updated_at": "2016-06-08T21:20:42.470Z",
  "merge_status": "cannot_be_merged",
  "approvals_required": 2,
  "approvals_left": 2,
  "approved_by": []
}
```

### Get the approval state of merge requests

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13712) in GitLab 12.3.
> - Moved to GitLab Premium in 13.9.

You can request information about a merge request's approval state by using the following endpoint:

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/approval_state
```

The `approval_rules_overwritten` are `true` if the merge request level rules
are created for the merge request. If there are none, it is `false`.

This includes additional information about the users who have already approved
(`approved_by`) and whether a rule is already approved (`approved`).

**Parameters:**

| Attribute            | Type    | Required | Description         |
|----------------------|---------|----------|---------------------|
| `id`                 | integer or string | yes      | The ID or [URL-encoded path of a project](index.md#namespaced-path-encoding) |
| `merge_request_iid`  | integer | yes      | The IID of MR       |

```json
{
  "approval_rules_overwritten": true,
  "rules": [
    {
      "id": 1,
      "name": "Ruby",
      "rule_type": "regular",
      "eligible_approvers": [
        {
          "id": 4,
          "name": "John Doe",
          "username": "jdoe",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "http://localhost/jdoe"
        }
      ],
      "approvals_required": 2,
      "users": [
        {
          "id": 4,
          "name": "John Doe",
          "username": "jdoe",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "http://localhost/jdoe"
        }
      ],
      "groups": [],
      "contains_hidden_groups": false,
      "approved_by": [
        {
          "id": 4,
          "name": "John Doe",
          "username": "jdoe",
          "state": "active",
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "http://localhost/jdoe"
        }
      ],
      "source_rule": null,
      "approved": true,
      "overridden": false
    }
  ]
}
```

### Get merge request level rules

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13712) in GitLab 12.3.
> - Moved to GitLab Premium in 13.9.

You can request information about a merge request's approval rules using the following endpoint:

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/approval_rules
```

**Parameters:**

| Attribute           | Type    | Required | Description         |
|---------------------|---------|----------|---------------------|
| `id`                | integer or string | yes      | The ID or [URL-encoded path of a project](index.md#namespaced-path-encoding) |
| `merge_request_iid` | integer | yes      | The IID of MR       |

```json
[
  {
    "id": 1,
    "name": "security",
    "rule_type": "regular",
    "eligible_approvers": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      },
      {
        "id": 50,
        "name": "Group Member 1",
        "username": "group_member_1",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/group_member_1"
      }
    ],
    "approvals_required": 3,
    "source_rule": null,
    "users": [
      {
        "id": 5,
        "name": "John Doe",
        "username": "jdoe",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "http://localhost/jdoe"
      }
    ],
    "groups": [
      {
        "id": 5,
        "name": "group1",
        "path": "group1",
        "description": "",
        "visibility": "public",
        "lfs_enabled": false,
        "avatar_url": null,
        "web_url": "http://localhost/groups/group1",
        "request_access_enabled": false,
        "full_name": "group1",
        "full_path": "group1",
        "parent_id": null,
        "ldap_cn": null,
        "ldap_access": null
      }
    ],
    "contains_hidden_groups": false,
    "overridden": false
  }
]
```

### Create merge request level rule

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11877) in GitLab 12.3.
> - Moved to GitLab Premium in 13.9.

You can create merge request approval rules using the following endpoint:

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/approval_rules
```

**Parameters:**

| Attribute                  | Type    | Required | Description                                    |
|----------------------------|---------|----------|------------------------------------------------|
| `id`                       | integer or string | yes      | The ID or [URL-encoded path of a project](index.md#namespaced-path-encoding) |
| `merge_request_iid`        | integer | yes      | The IID of MR                                  |
| `name`                     | string  | yes      | The name of the approval rule                  |
| `approvals_required`       | integer | yes      | The number of required approvals for this rule |
| `approval_project_rule_id` | integer | no       | The ID of a project-level approval rule        |
| `user_ids`                 | Array   | no       | The ids of users as approvers                  |
| `group_ids`                | Array   | no       | The ids of groups as approvers                 |

**Important:** When `approval_project_rule_id` is set, the `name`, `users` and
`groups` of project-level rule are copied. The `approvals_required` specified
is used.

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "eligible_approvers": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 1,
  "source_rule": null,
  "users": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "contains_hidden_groups": false,
  "overridden": false
}
```

### Update merge request level rule

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11877) in GitLab 12.3.
> - Moved to GitLab Premium in 13.9.

You can update merge request approval rules using the following endpoint:

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/approval_rules/:approval_rule_id
```

**Important:** Approvers and groups not in the `users`/`groups` parameters are **removed**

**Important:** Updating a `report_approver` or `code_owner` rule is not allowed.
These are system generated rules.

**Parameters:**

| Attribute            | Type    | Required | Description                                    |
|----------------------|---------|----------|------------------------------------------------|
| `id`                 | integer or string | yes      | The ID or [URL-encoded path of a project](index.md#namespaced-path-encoding) |
| `merge_request_iid`  | integer | yes      | The ID of MR                                   |
| `approval_rule_id`   | integer | yes      | The ID of a approval rule                      |
| `name`               | string  | yes      | The name of the approval rule                  |
| `approvals_required` | integer | yes      | The number of required approvals for this rule |
| `user_ids`           | Array   | no       | The ids of users as approvers                  |
| `group_ids`          | Array   | no       | The ids of groups as approvers                 |

```json
{
  "id": 1,
  "name": "security",
  "rule_type": "regular",
  "eligible_approvers": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    },
    {
      "id": 50,
      "name": "Group Member 1",
      "username": "group_member_1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/group_member_1"
    }
  ],
  "approvals_required": 1,
  "source_rule": null,
  "users": [
    {
      "id": 2,
      "name": "John Doe",
      "username": "jdoe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "http://localhost/jdoe"
    }
  ],
  "groups": [
    {
      "id": 5,
      "name": "group1",
      "path": "group1",
      "description": "",
      "visibility": "public",
      "lfs_enabled": false,
      "avatar_url": null,
      "web_url": "http://localhost/groups/group1",
      "request_access_enabled": false,
      "full_name": "group1",
      "full_path": "group1",
      "parent_id": null,
      "ldap_cn": null,
      "ldap_access": null
    }
  ],
  "contains_hidden_groups": false,
  "overridden": false
}
```

### Delete merge request level rule

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11877) in GitLab 12.3.
> - Moved to GitLab Premium in 13.9.

You can delete merge request approval rules using the following endpoint:

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/approval_rules/:approval_rule_id
```

**Important:** Deleting a `report_approver` or `code_owner` rule is not allowed.
These are system generated rules.

**Parameters:**

| Attribute           | Type    | Required | Description               |
|---------------------|---------|----------|---------------------------|
| `id`                | integer or string | yes      | The ID or [URL-encoded path of a project](index.md#namespaced-path-encoding) |
| `merge_request_iid` | integer | yes      | The IID of the merge request |
| `approval_rule_id`  | integer | yes      | The ID of an approval rule |

## Approve Merge Request

> - Introduced in GitLab 8.9.
> - Moved to GitLab Premium in 13.9.

If you are allowed to, you can approve a merge request using the following
endpoint:

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/approve
```

**Parameters:**

| Attribute           | Type    | Required | Description             |
|---------------------|---------|----------|-------------------------|
| `id`                | integer or string | yes      | The ID or [URL-encoded path of a project](index.md#namespaced-path-encoding) |
| `merge_request_iid` | integer | yes      | The IID of the merge request |
| `sha`               | string  | no       | The `HEAD` of the merge request |
| `approval_password` **(PREMIUM)** | string  | no      | Current user's password. Required if [**Require user password to approve**](../user/project/merge_requests/approvals/settings.md#require-authentication-for-approvals) is enabled in the project settings. |

The `sha` parameter works in the same way as
when [accepting a merge request](merge_requests.md#accept-mr): if it is passed, then it must
match the current HEAD of the merge request for the approval to be added. If it
does not match, the response code is `409`.

```json
{
  "id": 5,
  "iid": 5,
  "project_id": 1,
  "title": "Approvals API",
  "description": "Test",
  "state": "opened",
  "created_at": "2016-06-08T00:19:52.638Z",
  "updated_at": "2016-06-09T21:32:14.105Z",
  "merge_status": "can_be_merged",
  "approvals_required": 2,
  "approvals_left": 0,
  "approved_by": [
    {
      "user": {
        "name": "Administrator",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
        "web_url": "http://localhost:3000/root"
      }
    },
    {
      "user": {
        "name": "Nico Cartwright",
        "username": "ryley",
        "id": 2,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/cf7ad14b34162a76d593e3affca2adca?s=80\u0026d=identicon",
        "web_url": "http://localhost:3000/ryley"
      }
    }
  ]
}
```

## Unapprove Merge Request

> - Introduced in GitLab 9.0.
> - Moved to GitLab Premium in 13.9.

If you did approve a merge request, you can unapprove it using the following
endpoint:

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/unapprove
```

**Parameters:**

| Attribute           | Type    | Required | Description         |
|---------------------|---------|----------|---------------------|
| `id`                | integer or string | yes      | The ID or [URL-encoded path of a project](index.md#namespaced-path-encoding) |
| `merge_request_iid` | integer | yes      | The IID of a merge request |
