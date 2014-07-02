# Repositories

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
      "parents": [],
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

## Create a new tag

Creates new tag in the repository that points to the supplied ref.

```
POST /projects/:id/repository/tags
```

Parameters:

+ `id` (required) - The ID of a project
+ `tag_name` (required) - The name of a tag
+ `ref` (required) - Create tag using commit sha, another tag name, or branch name.

```json
[
  {
    "name": "v1.0.0",
    "commit": {
      "id": "2695effb5807a22ff3d138d593fd856244e155e7",
      "parents": [],
      "message": "Initial commit",
      "authored_date": "2012-05-28T04:42:42-07:00",
      "author_name": "John Smith",
      "author email": "john@example.com",
      "committer_name": "Jack Smith",
      "committed_date": "2012-05-28T04:42:42-07:00",
      "committer_email": "jack@example.com"
    },
    "protected": false
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
[
  {
    "name": "assets",
    "type": "tree",
    "mode": "040000",
    "id": "6229c43a7e16fcc7e95f923f8ddadb8281d9c6c6"
  },
  {
    "name": "contexts",
    "type": "tree",
    "mode": "040000",
    "id": "faf1cdf33feadc7973118ca42d35f1e62977e91f"
  },
  {
    "name": "controllers",
    "type": "tree",
    "mode": "040000",
    "id": "95633e8d258bf3dfba3a5268fb8440d263218d74"
  },
  {
    "name": "Rakefile",
    "type": "blob",
    "mode": "100644",
    "id": "35b2f05cbb4566b71b34554cf184a9d0bd9d46d6"
  },
  {
    "name": "VERSION",
    "type": "blob",
    "mode": "100644",
    "id": "803e4a4f3727286c3093c63870c2b6524d30ec4f"
  },
  {
    "name": "config.ru",
    "type": "blob",
    "mode": "100644",
    "id": "dfd2d862237323aa599be31b473d70a8a817943b"
  }
]
```


## Raw file content

Get the raw file contents for a file by commit sha and path.

```
GET /projects/:id/repository/blobs/:sha
```

Parameters:

+ `id` (required) - The ID of a project
+ `sha` (required) - The commit or branch name
+ `filepath` (required) - The path the file


## Raw blob content

Get the raw file contents for a blob by blob sha.

```
GET /projects/:id/repository/raw_blobs/:sha
```

Parameters:

+ `id` (required) - The ID of a project
+ `sha` (required) - The blob sha


## Get file archive

Get a an archive of the repository

```
GET /projects/:id/repository/archive
```

Parameters:
+ `id` (required) - The ID of a project
+ `sha` (optional) - The commit sha to download defaults to the tip of the default branch


## Compare branches, tags or commits

```
GET /projects/:id/repository/compare
```

Parameters:
+ `id` (required) - The ID of a project
+ `from` (required) - the commit sha or branch name
+ `to` (required) - the commit sha or branch name


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

Get repository contributors list

```
GET /projects/:id/repository/contributors
```

Parameters:
+ `id` (required) - The ID of a project

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
