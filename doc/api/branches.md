# Branches

## List repository branches

Get a list of repository branches from a project, sorted by name alphabetically.

```
GET /projects/:id/repository/branches
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a project |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/5/repository/branches
```

Example response:

```json
[
  {
    "name": "master",
    "protected": true,
    "developers_can_push": false,
    "developers_can_merge": false,
    "commit": {
      "author_email": "john@example.com",
      "author_name": "John Smith",
      "authored_date": "2012-06-27T05:51:39-07:00",
      "committed_date": "2012-06-28T03:44:20-07:00",
      "committer_email": "john@example.com",
      "committer_name": "John Smith",
      "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
      "message": "add projects API",
      "parent_ids": [
        "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
      ]
    }
  },
  ...
]
```

## Get single repository branch

Get a single project repository branch.

```
GET /projects/:id/repository/branches/:branch
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a project |
| `branch` | string | yes | The name of the branch |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/5/repository/branches/master
```

Example response:

```json
{
  "name": "master",
  "protected": true,
  "developers_can_push": false,
  "developers_can_merge": false,
  "commit": {
    "author_email": "john@example.com",
    "author_name": "John Smith",
    "authored_date": "2012-06-27T05:51:39-07:00",
    "committed_date": "2012-06-28T03:44:20-07:00",
    "committer_email": "john@example.com",
    "committer_name": "John Smith",
    "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
    "message": "add projects API",
    "parent_ids": [
      "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
    ]
  }
}
```

## Protect repository branch

Protects a single project repository branch. This is an idempotent function,
protecting an already protected repository branch still returns a `200 OK`
status code.

```
PUT /projects/:id/repository/branches/:branch/protect
```

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/5/repository/branches/master/protect?developers_can_push=true&developers_can_merge=true
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a project |
| `branch` | string | yes | The name of the branch |
| `developers_can_push` | boolean | no | Flag if developers can push to the branch |
| `developers_can_merge` | boolean | no | Flag if developers can merge to the branch |

Example response:

```json
{
  "commit": {
    "author_email": "john@example.com",
    "author_name": "John Smith",
    "authored_date": "2012-06-27T05:51:39-07:00",
    "committed_date": "2012-06-28T03:44:20-07:00",
    "committer_email": "john@example.com",
    "committer_name": "John Smith",
    "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
    "message": "add projects API",
    "parent_ids": [
      "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
    ]
  },
  "name": "master",
  "protected": true,
  "developers_can_push": true,
  "developers_can_merge": true
}
```

## Unprotect repository branch

Unprotects a single project repository branch. This is an idempotent function,
unprotecting an already unprotected repository branch still returns a `200 OK`
status code.

```
PUT /projects/:id/repository/branches/:branch/unprotect
```

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/5/repository/branches/master/unprotect
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a project |
| `branch` | string | yes | The name of the branch |

Example response:

```json
{
  "commit": {
    "author_email": "john@example.com",
    "author_name": "John Smith",
    "authored_date": "2012-06-27T05:51:39-07:00",
    "committed_date": "2012-06-28T03:44:20-07:00",
    "committer_email": "john@example.com",
    "committer_name": "John Smith",
    "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
    "message": "add projects API",
    "parent_ids": [
      "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
    ]
  },
  "name": "master",
  "protected": false,
  "developers_can_push": false,
  "developers_can_merge": false
}
```

## Create repository branch

```
POST /projects/:id/repository/branches
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`          | integer | yes | The ID of a project |
| `branch_name` | string  | yes | The name of the branch |
| `ref`         | string  | yes | The branch name or commit SHA to create branch from |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/5/repository/branches?branch_name=newbranch&ref=master"
```

Example response:

```json
{
  "commit": {
    "author_email": "john@example.com",
    "author_name": "John Smith",
    "authored_date": "2012-06-27T05:51:39-07:00",
    "committed_date": "2012-06-28T03:44:20-07:00",
    "committer_email": "john@example.com",
    "committer_name": "John Smith",
    "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
    "message": "add projects API",
    "parent_ids": [
      "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
    ]
  },
  "name": "newbranch",
  "protected": false,
  "developers_can_push": false,
  "developers_can_merge": false
}
```

It returns `200` if it succeeds or `400` if failed with an error message
explaining the reason.

## Delete repository branch

```
DELETE /projects/:id/repository/branches/:branch
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer | yes | The ID of a project |
| `branch`  | string  | yes | The name of the branch |

It returns `200` if it succeeds, `404` if the branch to be deleted does not exist
or `400` for other reasons. In case of an error, an explaining message is provided.

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/5/repository/branches/newbranch"
```

Example response:

```json
{
  "branch_name": "newbranch"
}
```
