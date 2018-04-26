# Merge request approvals **[STARTER]**

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

### Change configuration

>**Note:** This API endpoint is only available on 10.6 Starter and above.

If you are allowed to, you can change approval configuration using the following
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

### Change allowed approvers

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
        "web_url": "http://localhost:3000/u/root"
      }
    }
  ],
  "approvers": [],
  "approver_groups": []
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
| `approvals_required` | integer | yes      | Approvals required before MR can be merged |


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
  "approvers": [],
  "approver_groups": []
}
```

### Change allowed approvers for Merge Request

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
        "web_url": "http://localhost:3000/u/root" 
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

| Attribute           | Type    | Required | Description         |
|---------------------|---------|----------|---------------------|
| `id`                | integer | yes      | The ID of a project |
| `merge_request_iid` | integer | yes      | The IID of MR       |
| `sha`               | string  | no       | The HEAD of the MR  |

The `sha` parameter works in the same way as
when [accepting a merge request](#accept-mr): if it is passed, then it must
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
        "web_url": "http://localhost:3000/u/root"
      }
    },
    {
      "user": {
        "name": "Nico Cartwright",
        "username": "ryley",
        "id": 2,
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/cf7ad14b34162a76d593e3affca2adca?s=80\u0026d=identicon",
        "web_url": "http://localhost:3000/u/ryley"
      }
    }
  ],
  "approvers": [],
  "approver_groups": []
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
