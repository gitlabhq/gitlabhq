---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Documentation for the REST API for Git branches in GitLab.
title: Branches API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to manage [Git branches](../user/project/repository/branches/_index.md).

To change the branch protections configured for a project, use the [protected branches API](protected_branches.md).

## List repository branches

Get a list of repository branches from a project, sorted by name alphabetically. Search by name, or
use regular expressions to find specific branch patterns. Returns detailed information about the branch,
including its protection status, merge status, and commit details.

{{< alert type="note" >}}

This endpoint can be accessed without authentication if the repository is publicly accessible.

{{< /alert >}}

```plaintext
GET /projects/:id/repository/branches
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `regex`   | string            | No       | Return list of branches with names matching a [re2](https://github.com/google/re2/wiki/Syntax) regular expression. Cannot be used together with `search`. |
| `search`  | string            | No       | Return list of branches containing the search string. You can use `^term` to find branches that begin with `term`, and `term$` to find branches that end with `term`. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                  | Type                | Description |
|----------------------------|---------------------|-------------|
| `can_push`                 | boolean             | If `true`, the authenticated user can push to this branch. |
| `commit`                   | object              | Details about the most recent commit on the branch. |
| `commit.author_email`      | string              | Email address of the user who authored the change. |
| `commit.author_name`       | string              | Name of the user who authored the change. |
| `commit.authored_date`     | datetime (ISO 8601) | When the commit was authored. |
| `commit.committed_date`    | datetime (ISO 8601) | When the commit was committed. |
| `commit.committer_email`   | string              | Email address of the user who committed the change. |
| `commit.committer_name`    | string              | Name of the user who committed the change. |
| `commit.created_at`        | datetime (ISO 8601) | When the commit was created. |
| `commit.extended_trailers` | object              | Extended Git trailers parsed from the commit message. |
| `commit.id`                | string              | Full SHA of the commit. |
| `commit.message`           | string              | Full commit message. |
| `commit.parent_ids`        | array               | Array of parent commit SHAs. |
| `commit.short_id`          | string              | Abbreviated SHA of the commit. |
| `commit.title`             | string              | Title of the commit message. |
| `commit.trailers`          | object              | Git trailers parsed from the commit message. |
| `commit.web_url`           | string              | URL to view the commit in the GitLab UI. |
| `default`                  | boolean             | If `true`, the branch is the default branch for the project. |
| `developers_can_merge`     | boolean             | If `true`, users with at least the Developer role can merge to this branch. |
| `developers_can_push`      | boolean             | If `true`, users with at least the Developer role can push to this branch. |
| `merged`                   | boolean             | If `true`, the branch has been merged into the default branch. |
| `name`                     | string              | Name of the branch. |
| `protected`                | boolean             | If `true`, the branch is protected from force pushes and deletion. |
| `web_url`                  | string              | URL to view the branch in the GitLab UI. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/branches"
```

Example response:

```json
[
  {
    "name": "main",
    "merged": false,
    "protected": true,
    "default": true,
    "developers_can_push": false,
    "developers_can_merge": false,
    "can_push": true,
    "web_url": "https://gitlab.example.com/my-group/my-project/-/tree/main",
    "commit": {
      "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
      "short_id": "7b5c3cc",
      "created_at": "2024-06-28T03:44:20-07:00",
      "parent_ids": [
        "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
      ],
      "title": "add projects API",
      "message": "add projects API",
      "author_name": "John Smith",
      "author_email": "john@example.com",
      "authored_date": "2024-06-27T05:51:39-07:00",
      "committer_name": "John Smith",
      "committer_email": "john@example.com",
      "committed_date": "2024-06-28T03:44:20-07:00",
      "trailers": {},
      "extended_trailers": {},
      "web_url": "https://gitlab.example.com/my-group/my-project/-/commit/7b5c3cc8be40ee161ae89a06bba6229da1032a0c"
    }
  },
  ...
]
```

## Get single repository branch

Get a single project repository branch.

{{< alert type="note" >}}

This endpoint can be accessed without authentication if the repository is publicly accessible.

{{< /alert >}}

```plaintext
GET /projects/:id/repository/branches/:branch
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `branch`  | string            | Yes      | [URL-encoded name](rest/_index.md#namespaced-paths) of the branch. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                | Type    | Description |
|--------------------------|---------|-------------|
| `can_push`               | boolean | Whether the authenticated user can push to this branch. |
| `commit`                 | object  | Details about the latest commit on the branch. |
| `commit.author_email`    | string  | Email address of the commit author. |
| `commit.author_name`     | string  | Name of the commit author. |
| `commit.authored_date`   | string  | Date and time when the commit was authored, in ISO 8601 format. |
| `commit.committer_email` | string  | Email address of the user who committed the change. |
| `commit.committer_name`  | string  | Name of the user who committed the change. |
| `commit.committed_date`  | string  | Date and time when the commit was committed, in ISO 8601 format. |
| `commit.created_at`      | string  | Date and time when the commit was created, in ISO 8601 format. |
| `commit.extended_trailers` | object  | Extended Git trailers parsed from the commit message. |
| `commit.id`              | string  | Full SHA of the commit. |
| `commit.message`         | string  | Full commit message. |
| `commit.parent_ids`      | array   | Array of parent commit SHAs. |
| `commit.short_id`        | string  | Abbreviated SHA of the commit. |
| `commit.title`           | string  | Title of the commit message. |
| `commit.trailers`        | object  | Git trailers parsed from the commit message. |
| `commit.web_url`         | string  | URL to view the commit in the GitLab UI. |
| `default`                | boolean | Whether this is the default branch for the project. |
| `developers_can_merge`   | boolean | Whether users with the Developer role can merge to this branch. |
| `developers_can_push`    | boolean | Whether users with the Developer role can push to this branch. |
| `merged`                 | boolean | Whether the branch has been merged into the default branch. |
| `name`                   | string  | Name of the branch. |
| `protected`              | boolean | Whether the branch is protected from force pushes and deletion. |
| `web_url`                | string  | URL to view the branch in the GitLab UI. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/branches/main"
```

Example response:

```json
{
  "name": "main",
  "merged": false,
  "protected": true,
  "default": true,
  "developers_can_push": false,
  "developers_can_merge": false,
  "can_push": true,
  "web_url": "https://gitlab.example.com/my-group/my-project/-/tree/main",
  "commit": {
    "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
    "short_id": "7b5c3cc",
    "created_at": "2012-06-28T03:44:20-07:00",
    "parent_ids": [
      "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
    ],
    "title": "add projects API",
    "message": "add projects API",
    "author_name": "John Smith",
    "author_email": "john@example.com",
    "authored_date": "2012-06-27T05:51:39-07:00",
    "committer_name": "John Smith",
    "committer_email": "john@example.com",
    "committed_date": "2012-06-28T03:44:20-07:00",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/my-group/my-project/-/commit/7b5c3cc8be40ee161ae89a06bba6229da1032a0c"
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

```plaintext
POST /projects/:id/repository/branches
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `branch`  | string            | Yes      | Name of the branch. Cannot contain spaces or special characters except hyphens and underscores. |
| `ref`     | string            | Yes      | Branch name or commit SHA to create the branch from. |

If successful, returns [`201 Created`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                  | Type    | Description |
|----------------------------|---------|-------------|
| `can_push`                 | boolean | If `true`, the authenticated user can push to this branch. |
| `commit`                   | object  | Details about the latest commit on the branch. |
| `commit.author_email`      | string  | Email address of the commit author. |
| `commit.author_name`       | string  | Name of the commit author. |
| `commit.authored_date`     | string  | Date and time when the commit was authored, in ISO 8601 format. |
| `commit.committed_date`    | string  | Date and time when the commit was committed, in ISO 8601 format. |
| `commit.committer_email`   | string  | Email address of the user who committed the change. |
| `commit.committer_name`    | string  | Name of the user who committed the change. |
| `commit.created_at`        | string  | Date and time when the commit was created, in ISO 8601 format. |
| `commit.extended_trailers` | object  | Extended Git trailers parsed from the commit message. |
| `commit.id`                | string  | Full SHA of the commit. |
| `commit.message`           | string  | Full commit message. |
| `commit.parent_ids`        | array   | Array of parent commit SHAs. |
| `commit.short_id`          | string  | Abbreviated SHA of the commit. |
| `commit.title`             | string  | Title of the commit message. |
| `commit.trailers`          | object  | Git trailers parsed from the commit message. |
| `commit.web_url`           | string  | URL to view the commit in the GitLab UI. |
| `default`                  | boolean | If `true`, sets this branch is the default branch for the project. |
| `developers_can_merge`     | boolean | If `true`, users with the Developer role can merge to this branch. |
| `developers_can_push`      | boolean | If `true`, users with the Developer role can push to this branch. |
| `merged`                   | boolean | If `true`, the branch merged into the default branch. |
| `name`                     | string  | Name of the branch. |
| `protected`                | boolean | If `true`, the branch is protected from force pushes and deletion. |
| `web_url`                  | string  | URL to view the branch in the GitLab UI. |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/branches?branch=newbranch&ref=main"
```

Example response:

```json
{
  "commit": {
    "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
    "short_id": "7b5c3cc",
    "created_at": "2012-06-28T03:44:20-07:00",
    "parent_ids": [
      "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
    ],
    "title": "add projects API",
    "message": "add projects API",
    "author_name": "John Smith",
    "author_email": "john@example.com",
    "authored_date": "2012-06-27T05:51:39-07:00",
    "committer_name": "John Smith",
    "committer_email": "john@example.com",
    "committed_date": "2012-06-28T03:44:20-07:00",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/my-group/my-project/-/commit/7b5c3cc8be40ee161ae89a06bba6229da1032a0c"
  },
  "name": "newbranch",
  "merged": false,
  "protected": false,
  "default": false,
  "developers_can_push": false,
  "developers_can_merge": false,
  "can_push": true,
  "web_url": "https://gitlab.example.com/my-group/my-project/-/tree/newbranch"
}
```

## Delete repository branch

Delete a branch from the repository.

{{< alert type="note" >}}

In the case of an error, an explanation message is provided.

{{< /alert >}}

```plaintext
DELETE /projects/:id/repository/branches/:branch
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `branch`  | string            | Yes      | [URL-encoded name](rest/_index.md#namespaced-paths) of the branch. Cannot delete the default branch or protected branches. |

If successful, returns [`204 No Content`](rest/troubleshooting.md#status-codes).

Example request:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/branches/newbranch"
```

{{< alert type="note" >}}

Deleting a branch does not completely erase all related data.
Some information persists to maintain project history and to support recovery processes.
For more information, see [Handle sensitive information](../topics/git/undo.md#handle-sensitive-information).

{{< /alert >}}

## Delete merged branches

Deletes all branches that are merged into the project's default branch.

{{< alert type="note" >}}

[Protected branches](../user/project/repository/branches/protected.md) are not deleted as part of this operation.

{{< /alert >}}

```plaintext
DELETE /projects/:id/repository/merged_branches
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

If successful, returns [`202 Accepted`](rest/troubleshooting.md#status-codes).

Example request:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/merged_branches"
```

## Related topics

- [Branches](../user/project/repository/branches/_index.md)
- [Protected branches](../user/project/repository/branches/protected.md)
- [Protected branches API](protected_branches.md)
