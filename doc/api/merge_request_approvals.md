# Merge request approvals API **(STARTER)**

Configuration for approvals on all Merge Requests (MR) in the project. Must be authenticated for all endpoints.

## Project-level MR approvals

### Get Configuration

>**Note:** This API endpoint is only available on 10.6 Starter and above.

You can request information about a project's approval configuration using the
following endpoint:

```
GET /projects/:id/approvals
```

**Parameters:**

| Attribute | Type    | Required | Description         |
| --------- | ------- | -------- | ------------------- |
| `id`      | integer | yes      | The ID of a project |

```json
{
  "approvals_before_merge": 2,
  "reset_approvals_on_push": true,
  "disable_overriding_approvers_per_merge_request": false
}
```

### Change configuration

>**Note:** This API endpoint is only available on 10.6 Starter and above.

If you are allowed to, you can change approval configuration using the following
endpoint:

```
POST /projects/:id/approvals
```

**Parameters:**

| Attribute                                        | Type    | Required | Description                                                                                         |
| ------------------------------------------------ | ------- | -------- | --------------------------------------------------------------------------------------------------- |
| `id`                                             | integer | yes      | The ID of a project                                                                                 |
| `approvals_before_merge`                         | integer | no       | How many approvals are required before an MR can be merged. Deprecated in 12.0 in favor of Approval Rules API. |
| `reset_approvals_on_push`                        | boolean | no       | Reset approvals on a new push                                                                       |
| `disable_overriding_approvers_per_merge_request` | boolean | no       | Allow/Disallow overriding approvers per MR                                                          |
| `merge_requests_author_approval`                 | boolean | no       | Allow/Disallow authors from self approving merge requests; `true` means authors cannot self approve |
| `merge_requests_disable_committers_approval`     | boolean | no       | Allow/Disallow committers from self approving merge requests                                        |

```json
{
  "approvals_before_merge": 2,
  "reset_approvals_on_push": true,
  "disable_overriding_approvers_per_merge_request": false,
  "merge_requests_author_approval": false,
  "merge_requests_disable_committers_approval": false
}
```

### Get project-level rules

>**Note:** This API endpoint is only available on 12.3 Starter and above.

You can request information about a project's approval rules using the following endpoint:

```
GET /projects/:id/approval_rules
```

**Parameters:**

| Attribute            | Type    | Required | Description                                               |
|----------------------|---------|----------|-----------------------------------------------------------|
| `id`                 | integer | yes      | The ID of a project                                       |

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
    "contains_hidden_groups": false
  }
]
```

### Create project-level rule

>**Note:** This API endpoint is only available on 12.3 Starter and above.

You can create project approval rules using the following endpoint:

```
POST /projects/:id/approval_rules
```

**Parameters:**

| Attribute            | Type    | Required | Description                                               |
|----------------------|---------|----------|-----------------------------------------------------------|
| `id`                 | integer | yes      | The ID of a project                                       |
| `name`               | string  | yes      | The name of the approval rule                             |
| `approvals_required` | integer | yes      | The number of required approvals for this rule            |
| `user_ids`           | Array   | no       | The ids of users as approvers                             |
| `group_ids`          | Array   | no       | The ids of groups as approvers                            |

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
  "contains_hidden_groups": false
}
```

### Update project-level rule

>**Note:** This API endpoint is only available on 12.3 Starter and above.

You can update project approval rules using the following endpoint:

```
PUT /projects/:id/approval_rules/:approval_rule_id
```

**Important:** Approvers and groups not in the `users`/`groups` param will be **removed**

**Parameters:**

| Attribute            | Type    | Required | Description                                               |
|----------------------|---------|----------|-----------------------------------------------------------|
| `id`                 | integer | yes      | The ID of a project                                       |
| `approval_rule_id`   | integer | yes      | The ID of a approval rule                                 |
| `name`               | string  | yes      | The name of the approval rule                             |
| `approvals_required` | integer | yes      | The number of required approvals for this rule            |
| `user_ids`           | Array   | no       | The ids of users as approvers                             |
| `group_ids`          | Array   | no       | The ids of groups as approvers                            |

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
  "contains_hidden_groups": false
}
```

### Delete project-level rule

>**Note:** This API endpoint is only available on 12.3 Starter and above.

You can delete project approval rules using the following endpoint:

```
DELETE /projects/:id/approval_rules/:approval_rule_id
```

**Parameters:**

| Attribute            | Type    | Required | Description                                               |
|----------------------|---------|----------|-----------------------------------------------------------|
| `id`                 | integer | yes      | The ID of a project                                       |
| `approval_rule_id`   | integer | yes      | The ID of a approval rule

### Change allowed approvers

>**Note:** This API endpoint has been deprecated. Please use Approval Rule API instead.
>**Note:** This API endpoint is only available on 10.6 Starter and above.

If you are allowed to, you can change approvers and approver groups using
the following endpoint:

```
PUT /projects/:id/approvers
```

**Important:** Approvers and groups not in the request will be **removed**

**Parameters:**

| Attribute            | Type    | Required | Description                                         |
| -------------------- | ------- | -------- | --------------------------------------------------- |
| `id`                 | integer | yes      | The ID of a project                                 |
| `approver_ids`       | Array   | yes      | An array of User IDs that can approve MRs           |
| `approver_group_ids` | Array   | yes      | An array of Group IDs whose members can approve MRs |

```json
{
  "approvers": [
    {
      "user": {
        "id": 5,
        "name": "John Doe6",
        "username": "user5",
        "state":"active","avatar_url":"https://www.gravatar.com/avatar/4aea8cf834ed91844a2da4ff7ae6b491?s=80\u0026d=identicon","web_url":"http://localhost/user5"
      }
    }
  ],
  "approver_groups": [
    {
      "group": {
        "id": 1,
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
    }
  ],
  "approvals_before_merge": 2,
  "reset_approvals_on_push": true,
  "disable_overriding_approvers_per_merge_request": false
}
```

## Merge Request-level MR approvals

Configuration for approvals on a specific Merge Request. Must be authenticated for all endpoints.

### Get Configuration

>**Note:** This API endpoint is only available on 8.9 Starter and above.

You can request information about a merge request's approval status using the
following endpoint:

```
GET /projects/:id/merge_requests/:merge_request_iid/approvals
```

**Parameters:**

| Attribute           | Type    | Required | Description         |
|---------------------|---------|----------|---------------------|
| `id`                | integer | yes      | The ID of a project |
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
  ],
}
```

### Change approval configuration

>**Note:** This API endpoint is only available on 10.6 Starter and above.

If you are allowed to, you can change `approvals_required` using the following
endpoint:

```
POST /projects/:id/merge_requests/:merge_request_iid/approvals
```

**Parameters:**

| Attribute            | Type    | Required | Description                                |
|----------------------|---------|----------|--------------------------------------------|
| `id`                 | integer | yes      | The ID of a project                        |
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

### Change allowed approvers for Merge Request

>**Note:** This API endpoint has been deprecated. Please use Approval Rule API instead.
>**Note:** This API endpoint is only available on 10.6 Starter and above.

If you are allowed to, you can change approvers and approver groups using
the following endpoint:

```
PUT /projects/:id/merge_requests/:merge_request_iid/approvers
```

**Important:** Approvers and groups not in the request will be **removed**

**Parameters:**

| Attribute            | Type    | Required | Description                                               |
|----------------------|---------|----------|-----------------------------------------------------------|
| `id`                 | integer | yes      | The ID of a project                                       |
| `merge_request_iid`  | integer | yes      | The IID of MR                                             |
| `approver_ids`          | Array   | yes      | An array of User IDs that can approve the MR           |
| `approver_group_ids`    | Array   | yes      | An array of Group IDs whose members can approve the MR |

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
  "approved_by": [],
  "approvers": [
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
  ],
  "approver_groups": [
    {
      "group": {
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
    }
  ]
}
```

## Approve Merge Request

>**Note:** This API endpoint is only available on 8.9 Starter and above.

If you are allowed to, you can approve a merge request using the following
endpoint:

```
POST /projects/:id/merge_requests/:merge_request_iid/approve
```

**Parameters:**

| Attribute           | Type    | Required | Description             |
|---------------------|---------|----------|-------------------------|
| `id`                | integer | yes      | The ID of a project     |
| `merge_request_iid` | integer | yes      | The IID of MR           |
| `sha`               | string  | no       | The HEAD of the MR      |
| `approval_password` **(STARTER)** | string  | no      | Current user's password. Required if [**Require user password to approve**](../user/project/merge_requests/merge_request_approvals.md#require-authentication-when-approving-a-merge-request-starter) is enabled in the project settings. |

The `sha` parameter works in the same way as
when [accepting a merge request](merge_requests.md#accept-mr): if it is passed, then it must
match the current HEAD of the merge request for the approval to be added. If it
does not match, the response code will be `409`.

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
  ],
}
```

## Unapprove Merge Request

>**Note:** This API endpoint is only available on 9.0 Starter and above.

If you did approve a merge request, you can unapprove it using the following
endpoint:

```
POST /projects/:id/merge_requests/:merge_request_iid/unapprove
```

**Parameters:**

| Attribute           | Type    | Required | Description         |
|---------------------|---------|----------|---------------------|
| `id`                | integer | yes      | The ID of a project |
| `merge_request_iid` | integer | yes      | The IID of MR       |

### Get merge request level rules

>**Note:** This API endpoint is only available on 12.3 Starter and above.

You can request information about a merge request's approval rules using the following endpoint:

```
GET /projects/:id/merge_requests/:merge_request_iid/approval_rules
```

**Parameters:**

| Attribute           | Type    | Required | Description         |
|---------------------|---------|----------|---------------------|
| `id`                | integer | yes      | The ID of a project |
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
    "contains_hidden_groups": false
  }
]
```

### Create merge request level rule

>**Note:** This API endpoint is only available on 12.3 Starter and above.

You can create merge request approval rules using the following endpoint:

```
POST /projects/:id/merge_requests/:merge_request_iid/approval_rules
```

**Parameters:**

| Attribute                  | Type    | Required | Description                                    |
|----------------------------|---------|----------|------------------------------------------------|
| `id`                       | integer | yes      | The ID of a project                            |
| `merge_request_iid`        | integer | yes      | The IID of MR                                  |
| `name`                     | string  | yes      | The name of the approval rule                  |
| `approvals_required`       | integer | yes      | The number of required approvals for this rule |
| `approval_project_rule_id` | integer | no       | The ID of a project-level approval rule        |
| `user_ids`                 | Array   | no       | The ids of users as approvers                  |
| `group_ids`                | Array   | no       | The ids of groups as approvers                 |

**Important:** When `approval_project_rule_id` is set, the `name`, `users` and
`groups` of project-level rule will be copied. The `approvals_required` specified
will be used.

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
  "contains_hidden_groups": false
}
```

### Update merge request level rule

>**Note:** This API endpoint is only available on 12.3 Starter and above.

You can update merge request approval rules using the following endpoint:

```
PUT /projects/:id/merge_request/:merge_request_iid/approval_rules/:approval_rule_id
```

**Important:** Approvers and groups not in the `users`/`groups` param will be **removed**

**Important:** Updating a `report_approver` or `code_owner` rule is not allowed.
These are system generated rules.

**Parameters:**

| Attribute            | Type    | Required | Description                                    |
|----------------------|---------|----------|------------------------------------------------|
| `id`                 | integer | yes      | The ID of a project                            |
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
  "contains_hidden_groups": false
}
```

### Delete merge request level rule

>**Note:** This API endpoint is only available on 12.3 Starter and above.

You can delete merge request approval rules using the following endpoint:

```
DELETE /projects/:id/merge_requests/:merge_request_iid/approval_rules/:approval_rule_id
```

**Important:** Deleting a `report_approver` or `code_owner` rule is not allowed.
These are system generated rules.

**Parameters:**

| Attribute           | Type    | Required | Description               |
|---------------------|---------|----------|---------------------------|
| `id`                | integer | yes      | The ID of a project       |
| `merge_request_iid` | integer | yes      | The ID of MR              |
| `approval_rule_id`  | integer | yes      | The ID of a approval rule |
