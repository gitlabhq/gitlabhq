## List repository branches

Get a list of repository branches from a project, sorted by name alphabetically.

```
GET /projects/:id/repository/branches
```

Parameters:

+ `id` (required) - The ID of a project

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

+ `id` (required) - The ID of a project
+ `branch` (required) - The name of the branch

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

+ `id` (required) - The ID of a project
+ `branch` (required) - The name of the branch

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

+ `id` (required) - The ID of a project
+ `branch` (required) - The name of the branch

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


## List project repository tags

Get a list of repository tags from a project, sorted by name in reverse alphabetical order.

```
GET /projects/:id/repository/tags
```

Parameters:

+ `id` (required) - The ID of a project

```json
[
  {
    "name": "v1.0.0",
    "commit": {
      "id": "2695effb5807a22ff3d138d593fd856244e155e7",
      "parents": [

      ],
      "tree": "38017f2f189336fe4497e9d230c5bb1bf873f08d",
      "message": "Initial commit",
      "author": {
        "name": "John Smith",
        "email": "john@example.com"
      },
      "committer": {
        "name": "Jack Smith",
        "email": "jack@example.com"
      },
      "authored_date": "2012-05-28T04:42:42-07:00",
      "committed_date": "2012-05-28T04:42:42-07:00"
    },
    "protected": null
  }
]
```


## List repository commits

Get a list of repository commits in a project.

```
GET /projects/:id/repository/commits
```

Parameters:

+ `id` (required) - The ID of a project
+ `ref_name` (optional) - The name of a repository branch or tag or if not given the default branch

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

## List repository tree

Get a list of repository files and directories in a project.

```
GET /projects/:id/repository/tree
```

Parameters:

+ `id` (required) - The ID of a project
+ `path` (optional) - The path inside repository. Used to get contend of subdirectories
+ `ref_name` (optional) - The name of a repository branch or tag or if not given the default branch

```json

[{
  "name": "assets",
  "type": "tree",
  "mode": "040000",
  "id": "6229c43a7e16fcc7e95f923f8ddadb8281d9c6c6"
}, {
  "name": "contexts",
  "type": "tree",
  "mode": "040000",
  "id": "faf1cdf33feadc7973118ca42d35f1e62977e91f"
}, {
  "name": "controllers",
  "type": "tree",
  "mode": "040000",
  "id": "95633e8d258bf3dfba3a5268fb8440d263218d74"
}, {
  "name": "Rakefile",
  "type": "blob",
  "mode": "100644",
  "id": "35b2f05cbb4566b71b34554cf184a9d0bd9d46d6"
}, {
  "name": "VERSION",
  "type": "blob",
  "mode": "100644",
  "id": "803e4a4f3727286c3093c63870c2b6524d30ec4f"
}, {
  "name": "config.ru",
  "type": "blob",
  "mode": "100644",
  "id": "dfd2d862237323aa599be31b473d70a8a817943b"
}]

```


## Raw blob content

Get the raw file contents for a file.

```
GET /projects/:id/repository/commits/:sha/blob
```

Parameters:

+ `id` (required) - The ID of a project
+ `sha` (required) - The commit or branch name
+ `filepath` (required) - The path the file
