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

## List open merge requests

Get all open (i.e. non-closed, non-merged) MR for this project. This
returns a more filled out merge request object that includes commit and
note information.

```
GET /projects/:id/open_merge_requests
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
        },
        "mr_and_commit_notes": [
            {
                "attachment": {
                    "url": null
                },
                "author_id": 5,
                "commit_id": null,
                "created_at": "2013-02-01T15:13:15Z",
                "id": 159,
                "line_code": null,
                "note": ":-1: This needs more work.",
                "noteable_id": 27,
                "noteable_type": "MergeRequest",
                "project_id": 39,
                "updated_at": "2013-02-01T15:13:15Z"
            },
            {
                "attachment": {
                    "url": null
                },
                "author_id": 4,
                "commit_id": "",
                "created_at": "2013-02-02T09:59:57Z",
                "id": 161,
                "line_code": null,
                "note": ":+1: Seems legit",
                "noteable_id": 27,
                "noteable_type": "MergeRequest",
                "project_id": 39,
                "updated_at": "2013-02-02T09:59:57Z"
            }
        ],
        "unmerged_commits": [
            {
                "commit": {
                    "id": "f8b1ebe1a21aebee3b5c19d5216e7de40b7db43f",
                    "parents": [
                        {
                            "id": "10792ad4f8f42354aed2c5a4997b503171f5d1be"
                        }
                    ],
                    "tree": "eeb3e324299e458fe1b6e6fc709900a8ed7e5d94",
                    "message": "BUG: Don't frobble the quuxes.",
                    "author": {
                        "name": "johndoe",
                        "email": "john.doe@example.com"
                    },
                    "committer": {
                        "name": "johndoe",
                        "email": "john.doe@example.com"
                    },
                    "authored_date": "2013-02-01T16:12:44+01:00",
                    "committed_date": "2013-02-01T16:12:44+01:00"
                },
                "head": null
            }
        ]
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
