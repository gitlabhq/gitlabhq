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
    "name": "master",
    "commit": {
      "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
      "parents": [
        {
          "id": "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
        }
      ],
      "tree": "46e82de44b1061621357f24c05515327f2795a95",
      "message": "add projects API",
      "author": {
        "name": "John Smith",
        "email": "john@example.com"
      },
      "committer": {
        "name": "John Smith",
        "email": "john@example.com"
      },
      "authored_date": "2012-06-27T05:51:39-07:00",
      "committed_date": "2012-06-28T03:44:20-07:00"
    },
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
  "name": "master",
  "commit": {
    "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
    "parents": [
      {
        "id": "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
      }
    ],
    "tree": "46e82de44b1061621357f24c05515327f2795a95",
    "message": "add projects API",
    "author": {
      "name": "John Smith",
      "email": "john@example.com"
    },
    "committer": {
      "name": "John Smith",
      "email": "john@example.com"
    },
    "authored_date": "2012-06-27T05:51:39-07:00",
    "committed_date": "2012-06-28T03:44:20-07:00"
  },
  "protected": true
}
```

## Protect repository branch

Protects a single project repository branch. This is an idempotent function, protecting an already
protected repository branch still returns a `200 Ok` status code.

```
PUT /projects/:id/repository/branches/:branch/protect
```

Parameters:

- `id` (required) - The ID of a project
- `branch` (required) - The name of the branch

```json
{
  "name": "master",
  "commit": {
    "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
    "parents": [
      {
        "id": "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
      }
    ],
    "tree": "46e82de44b1061621357f24c05515327f2795a95",
    "message": "add projects API",
    "author": {
      "name": "John Smith",
      "email": "john@example.com"
    },
    "committer": {
      "name": "John Smith",
      "email": "john@example.com"
    },
    "authored_date": "2012-06-27T05:51:39-07:00",
    "committed_date": "2012-06-28T03:44:20-07:00"
  },
  "protected": true
}
```

## Unprotect repository branch

Unprotects a single project repository branch. This is an idempotent function, unprotecting an already
unprotected repository branch still returns a `200 Ok` status code.

```
PUT /projects/:id/repository/branches/:branch/unprotect
```

Parameters:

- `id` (required) - The ID of a project
- `branch` (required) - The name of the branch

```json
{
  "name": "master",
  "commit": {
    "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
    "parents": [
      {
        "id": "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
      }
    ],
    "tree": "46e82de44b1061621357f24c05515327f2795a95",
    "message": "add projects API",
    "author": {
      "name": "John Smith",
      "email": "john@example.com"
    },
    "committer": {
      "name": "John Smith",
      "email": "john@example.com"
    },
    "authored_date": "2012-06-27T05:51:39-07:00",
    "committed_date": "2012-06-28T03:44:20-07:00"
  },
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
- `ref` (required) - Create branch from commit sha or existing branch

```json
{
  "name": "my-new-branch",
  "commit": {
    "id": "8848c0e90327a0b70f1865b843fb2fbfb9345e57",
    "message": "Merge pull request #54 from brightbox/use_fog_brightbox_module\n\nUpdate to use fog-brightbox module",
    "parent_ids": [
      "fff449e0bf453576f16c91d6544f00a2664009d8",
      "f93a93626fec20fd659f4ed3ab2e64019b6169ae"
    ],
    "authored_date": "2014-02-20T19:54:55+02:00",
    "author_name": "john smith",
    "author_email": "john@example.com",
    "committed_date": "2014-02-20T19:54:55+02:00",
    "committer_name": "john smith",
    "committer_email": "john@example.com"
  },
  "protected": false
}
```

## Delete repository branch


```
DELETE /projects/:id/repository/branches/:branch
```

Parameters:

+ `id` (required) - The ID of a project
+ `branch` (required) - The name of the branch

It return 200 if succeed or 405 if failed with error message explaining reason.
