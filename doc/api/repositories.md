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
    "id": "72e10ef47e770a95439255b2c49de722e8782106",
    "short_id": "72e10ef47e7",
    "title": "Add NEWFILE",
    "author_name": "Dmitriy Zaporozhets",
    "author_email": "dmitriy.zaporozhets@gmail.com",
    "created_at": "2014-05-26T16:03:54+03:00"
  },
  "commits": [{
    "id": "0b4bc9a49b562e85de7cc9e834518ea6828729b9",
    "short_id": "0b4bc9a49b5",
    "title": "Feature added",
    "author_name": "Dmitriy Zaporozhets",
    "author_email": "dmitriy.zaporozhets@gmail.com",
    "created_at": "2014-02-27T10:26:01+02:00"
  }, {
    "id": "72e10ef47e770a95439255b2c49de722e8782106",
    "short_id": "72e10ef47e7",
    "title": "Add NEWFILE",
    "author_name": "Dmitriy Zaporozhets",
    "author_email": "dmitriy.zaporozhets@gmail.com",
    "created_at": "2014-05-26T16:03:54+03:00"
  }],
  "diffs": [{
    "old_path": "NEWFILE",
    "new_path": "NEWFILE",
    "a_mode": null,
    "b_mode": null,
    "diff": "--- /dev/null\n+++ b/NEWFILE\n@@ -0,0 +1 @@\n+This is NEWFILE content\n\\ No newline at end of file",
    "new_file": true,
    "renamed_file": false,
    "deleted_file": false
  }, {
    "old_path": "files/ruby/feature.rb",
    "new_path": "files/ruby/feature.rb",
    "a_mode": null,
    "b_mode": null,
    "diff": "--- /dev/null\n+++ b/files/ruby/feature.rb\n@@ -0,0 +1,5 @@\n+class Feature\n+  def foo\n+    puts 'bar'\n+  end\n+end",
    "new_file": true,
    "renamed_file": false,
    "deleted_file": false
  }]
}
```
