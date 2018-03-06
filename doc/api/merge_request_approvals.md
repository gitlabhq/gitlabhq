# Merge request approvals API

Every API call must be authenticated

## Merge Request Approvals

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
  "approvals_missing": 1,
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

## Change Merge Request approvals configuration

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
  "approvals_missing": 2,
  "approved_by": [],
  "approvers": [],
  "approver_groups": []
}
```

## Change allowed approvers for Merge Request

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
  "approvals_missing": 2,
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
