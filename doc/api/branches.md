# Branches

## List repository branches

Get a list of repository branches from a project, sorted by name alphabetically.

```
GET /projects/:id/repository/branches
```

Parameters:

- `id` (required) - The ID of a project

```json
[
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
    "protected": true
  }
]
```

## Get single repository branch

Get a single project repository branch.

```
GET /projects/:id/repository/branches/:branch
```

Parameters:

- `id` (required) - The ID of a project
- `branch` (required) - The name of the branch

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
  "protected": true
}
```

## Protect repository branch

Protects a single project repository branch. This is an idempotent function, protecting an already
protected repository branch still returns a `200 OK` status code.

```
PUT /projects/:id/repository/branches/:branch/protect
```

Parameters:

- `id` (required) - The ID of a project
- `branch` (required) - The name of the branch

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
  "protected": true
}
```

## Unprotect repository branch

Unprotects a single project repository branch. This is an idempotent function, unprotecting an already
unprotected repository branch still returns a `200 OK` status code.

```
PUT /projects/:id/repository/branches/:branch/unprotect
```

Parameters:

- `id` (required) - The ID of a project
- `branch` (required) - The name of the branch

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
  "protected": false
}
```

## Create repository branch

```
POST /projects/:id/repository/branches
```

Parameters:

- `id` (required) - The ID of a project
- `branch_name` (required) - The name of the branch
- `ref` (required) - Create branch from commit SHA or existing branch

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
  "protected": false
}
```

It return 200 if succeed or 400 if failed with error message explaining reason.

## Delete repository branch

```
DELETE /projects/:id/repository/branches/:branch
```

Parameters:

- `id` (required) - The ID of a project
- `branch` (required) - The name of the branch

It return 200 if succeed, 404 if the branch to be deleted does not exist
or 400 for other reasons. In case of an error, an explaining message is provided.

Success response: 

```json
{
  "branch_name": "my-removed-branch"
}
```
