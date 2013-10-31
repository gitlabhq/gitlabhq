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
        "iid":1,
        "target_branch":"master",
        "source_branch":"test1",
        "project_id":3,
        "title":"test1",
        "state":"opened",
        "upvotes":0,
        "downvotes":0,
        "author":{
            "id":1,
            "username": "admin",
            "email":"admin@local.host",
            "name":"Administrator",
            "state":"active",
            "created_at":"2012-04-29T08:46:00Z"
        },
        "assignee":{
            "id":1,
            "username": "admin",
            "email":"admin@local.host",
            "name":"Administrator",
            "state":"active",
            "created_at":"2012-04-29T08:46:00Z"
        }
    }
]
```


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
    "iid":1,
    "target_branch":"master",
    "source_branch":"test1",
    "project_id":3,
    "title":"test1",
    "state":"merged",
    "upvotes":0,
    "downvotes":0,
    "author":{
        "id":1,
        "username": "admin",
        "email":"admin@local.host",
        "name":"Administrator",
        "state":"active",
        "created_at":"2012-04-29T08:46:00Z"
    },
    "assignee":{
        "id":1,
        "username": "admin",
        "email":"admin@local.host",
        "name":"Administrator",
        "state":"active",
        "created_at":"2012-04-29T08:46:00Z"
    }
}
```


## Create MR

Creates a new merge request.

```
POST /projects/:id/merge_requests
```

Parameters:

+ `id` (required) - The ID of a project
+ `source_branch` (required) - The source branch
+ `target_branch` (required) - The target branch
+ `assignee_id` (optional)   - Assignee user ID
+ `title` (required)         - Title of MR

```json
{
    "id":1,
    "target_branch":"master",
    "source_branch":"test1",
    "project_id":3,
    "title":"test1",
    "state":"opened",
    "upvotes":0,
    "downvotes":0,
    "author":{
        "id":1,
        "username": "admin",
        "email":"admin@local.host",
        "name":"Administrator",
        "state":"active",
        "created_at":"2012-04-29T08:46:00Z"
    },
    "assignee":{
        "id":1,
        "username": "admin",
        "email":"admin@local.host",
        "name":"Administrator",
        "state":"active",
        "created_at":"2012-04-29T08:46:00Z"
    }
}
```


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

```json

{
    "id":1,
    "target_branch":"master",
    "source_branch":"test1",
    "project_id":3,
    "title":"test1",
    "state":"opened",
    "upvotes":0,
    "downvotes":0,
    "author":{
        "id":1,
        "username": "admin",
        "email":"admin@local.host",
        "name":"Administrator",
        "state":"active",
        "created_at":"2012-04-29T08:46:00Z"
    },
    "assignee":{
        "id":1,
        "username": "admin",
        "email":"admin@local.host",
        "name":"Administrator",
        "state":"active",
        "created_at":"2012-04-29T08:46:00Z"
    }
}
```


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
