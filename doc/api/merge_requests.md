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


## Get commits for single MR

Shows unmerged commits for a single merge request.

```
GET /projects/:id/merge_request/:merge_request_id/commits
```

Parameters:

+ `id` (required) - The ID of a project
+ `merge_request_id` (required) - The ID of MR

```json
[
  {
    "id": "ed899a2f4b50b4370feeea94676502b42383c746",
    "short_id": "ed899a2f4b5",
    "title": "Replace sanitize with escape once",
    "author_name": "Dmitriy Zaporozhets",
    "author_email": "dzaporozhets@sphereconsultinginc.com",
    "created_at": "2012-09-20T11:50:22+03:00"
  },
  {
    "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
    "short_id": "6104942438c",
    "title": "Sanitize for network graph",
    "author_name": "randx",
    "author_email": "dmitriy.zaporozhets@gmail.com",
    "created_at": "2012-09-20T09:06:12+03:00"
  }
]
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
