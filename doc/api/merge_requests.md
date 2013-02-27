## List merge requests

Get all merge requests for this project. This function takes pagination parameters
`page` and `per_page` to restrict the list of merge requests.

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

Return values:

+ `200 Ok` on success and the list of merge requests
+ `401 Unauthorized` if user is not authenticated
+ `404 Not Found` if project ID not found


## Get single MR

Shows information about a single merge request.

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

Return values:

+ `200 Ok` on success and the single merge request
+ `401 Unauthorized` if user is not authenticated
+ `404 Not Found` if project ID or merge request ID not found


## Create MR

Creates a new merge request.

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

Return values:

+ `201 Created` on success and the created merge request
+ `400 Bad Request` if one of the required attributes is missing
+ `401 Unauthorize` if user is not authenticated or not allowed
+ `403 Forbidden` if user is not allowed to create a merge request
+ `404 Not Found` if project ID not found or something else fails


## Update MR

Updates an existing merge request. You can change branches, title, or even close the MR.

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

Return values:

+ `200 Ok` on success and the updated merge request
+ `401 Unauthorize` if user is not authenticated or not allowed
+ `403 Forbidden` if user is not allowed to update the merge request
+ `404 Not Found` if project ID or merge request ID not found


## Post comment to MR

Adds a comment to a merge request.

```
POST /projects/:id/merge_request/:merge_request_id/comments
```

Parameters:

+ `id` (required) - The ID of a project
+ `merge_request_id` (required) - ID of merge request
+ `note` (required) - Text of comment


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

Return values:

+ `201 Created` on success and the new comment
+ `400 Bad Request` if the required attribute note is not given
+ `401 Unauthorized` if user is not authenticated
+ `404 Not Found` if project ID or merge request ID not found
