# Branches API

This API operates on [repository branches](../user/project/repository/branches/index.md).

TIP: **Tip:**
See also [Protected branches API](protected_branches.md).

## List repository branches

Get a list of repository branches from a project, sorted by name alphabetically.

NOTE: **Note:**
This endpoint can be accessed without authentication if the repository is publicly accessible.

```text
GET /projects/:id/repository/branches
```

Parameters:

| Attribute | Type           | Required | Description |
|:----------|:---------------|:---------|:------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user.|
| `search`  | string         | no       | Return list of branches containing the search string. You can use `^term` and `term$` to find branches that begin and end with `term` respectively. |

Example request:

```sh
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/repository/branches
```

Example response:

```json
[
  {
    "name": "master",
    "merged": false,
    "protected": true,
    "default": true,
    "developers_can_push": false,
    "developers_can_merge": false,
    "can_push": true,
    "commit": {
      "author_email": "john@example.com",
      "author_name": "John Smith",
      "authored_date": "2012-06-27T05:51:39-07:00",
      "committed_date": "2012-06-28T03:44:20-07:00",
      "committer_email": "john@example.com",
      "committer_name": "John Smith",
      "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
      "short_id": "7b5c3cc",
      "title": "add projects API",
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

NOTE: **Note:**
This endpoint can be accessed without authentication if the repository is publicly accessible.

```text
GET /projects/:id/repository/branches/:branch
```

Parameters:

| Attribute | Type           | Required | Description                                                                                                  |
|:----------|:---------------|:---------|:-------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `branch`  | string         | yes      | Name of the branch.                                                                                          |

Example request:

```sh
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/repository/branches/master
```

Example response:

```json
{
  "name": "master",
  "merged": false,
  "protected": true,
  "default": true,
  "developers_can_push": false,
  "developers_can_merge": false,
  "can_push": true,
  "commit": {
    "author_email": "john@example.com",
    "author_name": "John Smith",
    "authored_date": "2012-06-27T05:51:39-07:00",
    "committed_date": "2012-06-28T03:44:20-07:00",
    "committer_email": "john@example.com",
    "committer_name": "John Smith",
    "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
    "short_id": "7b5c3cc",
    "title": "add projects API",
    "message": "add projects API",
    "parent_ids": [
      "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
    ]
  }
}
```

## Protect repository branch

See [`POST /projects/:id/protected_branches`](protected_branches.md#protect-repository-branches) for
information on protecting repository branches.

## Unprotect repository branch

See [`DELETE /projects/:id/protected_branches/:name`](protected_branches.md#unprotect-repository-branches)
for information on unprotecting repository branches.

## Create repository branch

Create a new branch in the repository.

```text
POST /projects/:id/repository/branches
```

Parameters:

| Attribute | Type    | Required | Description                                                                                                  |
|:----------|:--------|:---------|:-------------------------------------------------------------------------------------------------------------|
| `id`      | integer | yes      | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `branch`  | string  | yes      | Name of the branch.                                                                                          |
| `ref`     | string  | yes      | Branch name or commit SHA to create branch from.                                                             |

Example request:

```sh
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/repository/branches?branch=newbranch&ref=master
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
    "short_id": "7b5c3cc",
    "title": "add projects API",
    "message": "add projects API",
    "parent_ids": [
      "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
    ]
  },
  "name": "newbranch",
  "merged": false,
  "protected": false,
  "default": false,
  "developers_can_push": false,
  "developers_can_merge": false,
  "can_push": true
}
```

## Delete repository branch

Delete a branch from the repository.

NOTE: **Note:**
In the case of an error, an explanation message is provided.

```text
DELETE /projects/:id/repository/branches/:branch
```

Parameters:

| Attribute | Type           | Required | Description                                                                                                  |
|:----------|:---------------|:---------|:-------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `branch`  | string         | yes      | Name of the branch.                                                                                          |

Example request:

```sh
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/repository/branches/newbranch
```

## Delete merged branches

Will delete all branches that are merged into the project's default branch.

NOTE: **Note:**
[Protected branches](../user/project/protected_branches.md) will not be deleted as part of this operation.

```text
DELETE /projects/:id/repository/merged_branches
```

Parameters:

| Attribute | Type           | Required | Description                                                                                                  |
|:----------|:---------------|:---------|:-------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |

Example request:

```sh
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/repository/merged_branches
```
