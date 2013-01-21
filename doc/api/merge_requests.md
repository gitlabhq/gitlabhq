## List merge requests

Get all MR for this project.

```
GET /projects/:id/merge_requests
```

Parameters:

+ `id` (required) - The ID of a project

```json
[
    {
        "id":1,
        "target_branch":"master",
        "source_branch":"test1",
        "project_id":3,
        "title":"test1",
        "closed":true,
        "merged":false,
        "author":{
            "id":1,
            "username": "admin",
            "email":"admin@local.host",
            "name":"Administrator",
            "blocked":false,
            "created_at":"2012-04-29T08:46:00Z"
        },
        "assignee":{
            "id":1,
            "username": "admin",
            "email":"admin@local.host",
            "name":"Administrator",
            "blocked":false,
            "created_at":"2012-04-29T08:46:00Z"
        }
    }
]
```

## Show MR

Show information about MR.

```
GET /projects/:id/merge_request/:merge_request_id
```

Parameters:

+ `id` (required) - The ID of a project
+ `merge_request_id` (required) - The ID of MR

```json
{
    "id":1,
    "target_branch":"master",
    "source_branch":"test1",
    "project_id":3,
    "title":"test1",
    "closed":true,
    "merged":false,
    "author":{
        "id":1,
        "username": "admin",
        "email":"admin@local.host",
        "name":"Administrator",
        "blocked":false,
        "created_at":"2012-04-29T08:46:00Z"
    },
    "assignee":{
        "id":1,
        "username": "admin",
        "email":"admin@local.host",
        "name":"Administrator",
        "blocked":false,
        "created_at":"2012-04-29T08:46:00Z"
    }
}
```


## Create MR

Create MR.

```
POST /projects/:id/merge_requests
```

Parameters:

+ `id` (required) - The ID of a project
+ `source_branch` (required) - The source branch
+ `target_branch` (required) - The target branch
+ `assignee_id`              - Assignee user ID
+ `title` (required)         - Title of MR

```json
{
    "id":1,
    "target_branch":"master",
    "source_branch":"test1",
    "project_id":3,
    "title":"test1",
    "closed":true,
    "merged":false,
    "author":{
        "id":1,
        "username": "admin",
        "email":"admin@local.host",
        "name":"Administrator",
        "blocked":false,
        "created_at":"2012-04-29T08:46:00Z"
    },
    "assignee":{
        "id":1,
        "username": "admin",
        "email":"admin@local.host",
        "name":"Administrator",
        "blocked":false,
        "created_at":"2012-04-29T08:46:00Z"
    }
}
```

## Update MR

Update MR. You can change branches, title, or even close the MR.

```
PUT /projects/:id/merge_request/:merge_request_id
```

Parameters:

+ `id` (required)               - The ID of a project
+ `merge_request_id` (required) - ID of MR
+ `source_branch`               - The source branch
+ `target_branch`               - The target branch
+ `assignee_id`                 - Assignee user ID
+ `title`                       - Title of MR
+ `closed`                      - Status of MR. true - closed


```json
{
    "id":1,
    "target_branch":"master",
    "source_branch":"test1",
    "project_id":3,
    "title":"test1",
    "closed":true,
    "merged":false,
    "author":{
        "id":1,
        "username": "admin",
        "email":"admin@local.host",
        "name":"Administrator",
        "blocked":false,
        "created_at":"2012-04-29T08:46:00Z"
    },
    "assignee":{
        "id":1,
        "username": "admin",
        "email":"admin@local.host",
        "name":"Administrator",
        "blocked":false,
        "created_at":"2012-04-29T08:46:00Z"
    }
}
```
## Post comment to MR

Post comment to MR

```
POST /projects/:id/merge_request/:merge_request_id/comments
```

Parameters:

+ `id` (required) - The ID of a project
+ `merge_request_id` (required) - ID of MR
+ `note` (required) - Text of comment

Will return created note with status `201 Created` on success, or `404 Not found` on fail.

```json
{
    "author":{
        "id":1,
        "username": "admin",
        "email":"admin@local.host",
        "name":"Administrator",
        "blocked":false,
        "created_at":"2012-04-29T08:46:00Z"
    },
    "note":"text1"
}
```
