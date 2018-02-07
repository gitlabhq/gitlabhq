# Repositories API

## List repository tree

Get a list of repository files and directories in a project. This endpoint can
be accessed without authentication if the repository is publicly accessible.

This command provides essentially the same functionality as the `git ls-tree` command. For more information, see the section _Tree Objects_ in the [Git internals documentation](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects/#_tree_objects).

```
GET /projects/:id/repository/tree
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `path` (optional) - The path inside repository. Used to get contend of subdirectories
- `ref` (optional) - The name of a repository branch or tag or if not given the default branch
- `recursive` (optional) - Boolean value used to get a recursive tree (false by default)

```json
[
  {
    "id": "a1e8f8d745cc87e3a9248358d9352bb7f9a0aeba",
    "name": "html",
    "type": "tree",
    "path": "files/html",
    "mode": "040000"
  },
  {
    "id": "4535904260b1082e14f867f7a24fd8c21495bde3",
    "name": "images",
    "type": "tree",
    "path": "files/images",
    "mode": "040000"
  },
  {
    "id": "31405c5ddef582c5a9b7a85230413ff90e2fe720",
    "name": "js",
    "type": "tree",
    "path": "files/js",
    "mode": "040000"
  },
  {
    "id": "cc71111cfad871212dc99572599a568bfe1e7e00",
    "name": "lfs",
    "type": "tree",
    "path": "files/lfs",
    "mode": "040000"
  },
  {
    "id": "fd581c619bf59cfdfa9c8282377bb09c2f897520",
    "name": "markdown",
    "type": "tree",
    "path": "files/markdown",
    "mode": "040000"
  },
  {
    "id": "23ea4d11a4bdd960ee5320c5cb65b5b3fdbc60db",
    "name": "ruby",
    "type": "tree",
    "path": "files/ruby",
    "mode": "040000"
  },
  {
    "id": "7d70e02340bac451f281cecf0a980907974bd8be",
    "name": "whitespace",
    "type": "blob",
    "path": "files/whitespace",
    "mode": "100644"
  }
]
```

## Get a blob from repository

Allows you to receive information about blob in repository like size and
content. Note that blob content is Base64 encoded. This endpoint can be accessed
without authentication if the repository is publicly accessible.

```
GET /projects/:id/repository/blobs/:sha
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `sha` (required) - The blob SHA

## Raw blob content

Get the raw file contents for a blob by blob SHA. This endpoint can be accessed
without authentication if the repository is publicly accessible.

```
GET /projects/:id/repository/blobs/:sha/raw
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `sha` (required) - The blob SHA

## Get file archive

Get an archive of the repository. This endpoint can be accessed without
authentication if the repository is publicly accessible.

```
GET /projects/:id/repository/archive
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `sha` (optional) - The commit SHA to download. A tag, branch reference or sha can be used. This defaults to the tip of the default branch if not specified
- `format` (optional) - The archive format. Default is `tar.gz`. Options are `tar.gz`, `tar.bz2`, `tbz`, `tbz2`, `tb2`, `bz2`, `tar`, `zip`

## Compare branches, tags or commits

This endpoint can be accessed without authentication if the repository is
publicly accessible.

```
GET /projects/:id/repository/compare
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `from` (required) - the commit SHA or branch name
- `to` (required) - the commit SHA or branch name

```
GET /projects/:id/repository/compare?from=master&to=feature
```

Response:

```json

{
  "commit": {
    "id": "12d65c8dd2b2676fa3ac47d955accc085a37a9c1",
    "short_id": "12d65c8dd2b",
    "title": "JS fix",
    "author_name": "Dmitriy Zaporozhets",
    "author_email": "dmitriy.zaporozhets@gmail.com",
    "created_at": "2014-02-27T10:27:00+02:00"
  },
  "commits": [{
    "id": "12d65c8dd2b2676fa3ac47d955accc085a37a9c1",
    "short_id": "12d65c8dd2b",
    "title": "JS fix",
    "author_name": "Dmitriy Zaporozhets",
    "author_email": "dmitriy.zaporozhets@gmail.com",
    "created_at": "2014-02-27T10:27:00+02:00"
  }],
  "diffs": [{
    "old_path": "files/js/application.js",
    "new_path": "files/js/application.js",
    "a_mode": null,
    "b_mode": "100644",
    "diff": "--- a/files/js/application.js\n+++ b/files/js/application.js\n@@ -24,8 +24,10 @@\n //= require g.raphael-min\n //= require g.bar-min\n //= require branch-graph\n-//= require highlightjs.min\n-//= require ace/ace\n //= require_tree .\n //= require d3\n //= require underscore\n+\n+function fix() { \n+  alert(\"Fixed\")\n+}",
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false
  }],
  "compare_timeout": false,
  "compare_same_ref": false
}
```

## Contributors

Get repository contributors list. This endpoint can be accessed without
authentication if the repository is publicly accessible.

```
GET /projects/:id/repository/contributors
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `order_by` (optional) - Return contributors ordered by `name`, `email`, or `commits` fields. If not given contributors are ordered by commit date.
- `sort` (optional) - Return contributors sorted in `asc` or `desc` order. Default is `asc`

Response:

```
[{
  "name": "Dmitriy Zaporozhets",
  "email": "dmitriy.zaporozhets@gmail.com",
  "commits": 117,
  "additions": 2097,
  "deletions": 517
}, {
  "name": "Jacob Vosmaer",
  "email": "contact@jacobvosmaer.nl",
  "commits": 33,
  "additions": 338,
  "deletions": 244
}]
```
