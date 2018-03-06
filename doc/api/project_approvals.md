# Project approvals API

Global configuration for approvals on all Merge Requests in the project. Must be authenticated for all endpoints.

## Project Approvals

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

## Change project approvals configuration

>**Note:** This API endpoint is only available on 10.6 Starter and above.

If you are allowed to, you can change global approval configuration using the following
endpoint:

```
POST /projects/:id/approvals
```

**Parameters:**

| Attribute                                        | Type    | Required | Description                                                |
| ------------------------------------------------ | ------- | -------- | ---------------------------------------------------------- |
| `id`                                             | integer | yes      | The ID of a project                                        |
| `approvals_before_merge`                         | integer | no       | How many approvals are required before an MR can be merged |
| `reset_approvals_on_push`                        | boolean | no       | Reset approvals on a new push                              |
| `disable_overriding_approvers_per_merge_request` | boolean | no       | Allow/Disallow overriding approvers per MR                 |

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

## Change allowed approvers globally for Project

>**Note:** This API endpoint is only available on 10.6 Starter and above.

If you are allowed to, you can change global approvers and approver groups using
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
