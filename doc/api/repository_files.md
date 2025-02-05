---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Documentation for the REST API for managing Git repository files in GitLab."
title: Repository files API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can fetch, create, update, and delete files in your repository with this API.
You can also [configure rate limits](../administration/settings/files_api_rate_limits.md)
for this API.

## Available scopes for personal access tokens

[Personal access tokens](../user/profile/personal_access_tokens.md) support these scopes:

| Scope             | Description |
|-------------------|-------------|
| `api`             | Allows read-write access to the repository files. |
| `read_api`        | Allows read access to the repository files. |
| `read_repository` | Allows read-access to the repository files. |

## Get file from repository

Allows you to receive information about file in repository like name, size, and
content. File content is Base64 encoded. You can access this endpoint
without authentication, if the repository is publicly accessible.

```plaintext
GET /projects/:id/repository/files/:file_path
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fmodels%2Fkey%2Erb?ref=main"
```

| Attribute   | Type           | Required | Description |
|-------------|----------------|----------|-------------|
| `id`        | integer or string | yes   | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `file_path` | string         | yes      | URL encoded full path to new file, such as `lib%2Fclass%2Erb`. |
| `ref`       | string         | yes      | The name of branch, tag or commit. |

### Response

In the response, `blob_id` is the blob SHA. See
[Get a blob from repository](repositories.md#get-a-blob-from-repository) in the Repositories API.

Example response:

```json
{
  "file_name": "key.rb",
  "file_path": "app/models/key.rb",
  "size": 1476,
  "encoding": "base64",
  "content": "IyA9PSBTY2hlbWEgSW5mb3...",
  "content_sha256": "4c294617b60715c1d218e61164a3abd4808a4284cbc30e6728a01ad9aada4481",
  "ref": "main",
  "blob_id": "79f7bbd25901e8334750839545a9bd021f0e4c83",
  "commit_id": "d5a3ff139356ce33e37e73add446f16869741b50",
  "last_commit_id": "570e7b2abdd848b95f2f578043fc23bd6f6fd24d",
  "execute_filemode": false
}
```

### Get file metadata only

You can also use `HEAD` to fetch just file metadata.

```plaintext
HEAD /projects/:id/repository/files/:file_path
```

```shell
curl --head --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fmodels%2Fkey%2Erb?ref=main"
```

Example response:

```plaintext
HTTP/1.1 200 OK
...
X-Gitlab-Blob-Id: 79f7bbd25901e8334750839545a9bd021f0e4c83
X-Gitlab-Commit-Id: d5a3ff139356ce33e37e73add446f16869741b50
X-Gitlab-Content-Sha256: 4c294617b60715c1d218e61164a3abd4808a4284cbc30e6728a01ad9aada4481
X-Gitlab-Encoding: base64
X-Gitlab-File-Name: key.rb
X-Gitlab-File-Path: app/models/key.rb
X-Gitlab-Last-Commit-Id: 570e7b2abdd848b95f2f578043fc23bd6f6fd24d
X-Gitlab-Ref: main
X-Gitlab-Size: 1476
X-Gitlab-Execute-Filemode: false
...
```

## Get file blame from repository

Retrieve blame information. Each blame range contains lines and their corresponding commit information.

```plaintext
GET /projects/:id/repository/files/:file_path/blame
```

| Attribute       | Type              | Required | Description |
|-----------------|-------------------|----------|-------------|
| `file_path`     | string            | yes   | URL-encoded full path to new file, such as`lib%2Fclass%2Erb`. |
| `id`            | integer or string | yes   | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `range[end]`    | integer           | yes   | The last line of the range to blame. |
| `range[start]`  | integer           | yes   | The first line of the range to blame. |
| `ref`           | string            | yes   | The name of branch, tag or commit. |
| `range`         | hash              | no    | Blame range. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/path%2Fto%2Ffile.rb/blame?ref=main"
```

Example response:

```json
[
  {
    "commit": {
      "id": "d42409d56517157c48bf3bd97d3f75974dde19fb",
      "message": "Add feature\n\nalso fix bug\n",
      "parent_ids": [
        "cc6e14f9328fa6d7b5a0d3c30dc2002a3f2a3822"
      ],
      "authored_date": "2015-12-18T08:12:22.000Z",
      "author_name": "John Doe",
      "author_email": "john.doe@example.com",
      "committed_date": "2015-12-18T08:12:22.000Z",
      "committer_name": "John Doe",
      "committer_email": "john.doe@example.com"
    },
    "lines": [
      "require 'fileutils'",
      "require 'open3'",
      ""
    ]
  },
  ...
]
```

### Get file metadata only

Use the `HEAD` method to return just file metadata, as in
[Get file from repository](repository_files.md#get-file-from-repository):

```shell
curl --head --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/path%2Fto%2Ffile.rb/blame?ref=main"
```

#### Response

Example response:

```plaintext
HTTP/1.1 200 OK
...
X-Gitlab-Blob-Id: 79f7bbd25901e8334750839545a9bd021f0e4c83
X-Gitlab-Commit-Id: d5a3ff139356ce33e37e73add446f16869741b50
X-Gitlab-Content-Sha256: 4c294617b60715c1d218e61164a3abd4808a4284cbc30e6728a01ad9aada4481
X-Gitlab-Encoding: base64
X-Gitlab-File-Name: file.rb
X-Gitlab-File-Path: path/to/file.rb
X-Gitlab-Last-Commit-Id: 570e7b2abdd848b95f2f578043fc23bd6f6fd24d
X-Gitlab-Ref: main
X-Gitlab-Size: 1476
X-Gitlab-Execute-Filemode: false
...
```

### Request a blame range

To request a blame range, specify `range[start]` and `range[end]` parameters with
the starting and ending line numbers of the file.

```shell
curl --head --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/path%2Fto%2Ffile.rb/blame?ref=main&range[start]=1&range[end]=2"
```

Example response:

```json
[
  {
    "commit": {
      "id": "d42409d56517157c48bf3bd97d3f75974dde19fb",
      "message": "Add feature\n\nalso fix bug\n",
      "parent_ids": [
        "cc6e14f9328fa6d7b5a0d3c30dc2002a3f2a3822"
      ],
      "authored_date": "2015-12-18T08:12:22.000Z",
      "author_name": "John Doe",
      "author_email": "john.doe@example.com",
      "committed_date": "2015-12-18T08:12:22.000Z",
      "committer_name": "John Doe",
      "committer_email": "john.doe@example.com"
    },
    "lines": [
      "require 'fileutils'",
      "require 'open3'"
    ]
  },
  ...
]
```

## Get raw file from repository

```plaintext
GET /projects/:id/repository/files/:file_path/raw
```

| Attribute   | Type           | Required | Description |
|-------------|----------------|----------|------------|
| `file_path` | string         | yes      | URL-encoded full path to new file, such as `lib%2Fclass%2Erb`. |
| `id`        | integer or string | yes   | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `lfs`       | boolean        | no       | Determines if the response should be Git LFS file contents, rather than the pointer. Ignored if the file is not tracked by Git LFS. Defaults to `false`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27892) in GitLab 15.7. |
| `ref`       | string         | no       | The name of branch, tag or commit. Default is the `HEAD` of the project. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fmodels%2Fkey%2Erb/raw?ref=main"
```

NOTE:
Like [Get file from repository](repository_files.md#get-file-from-repository), you can use `HEAD` to get just file metadata.

## Create new file in repository

Allows you to create a single file. For creating multiple files with a single request,
see the [commits API](commits.md#create-a-commit-with-multiple-files-and-actions).

```plaintext
POST /projects/:id/repository/files/:file_path
```

| Attribute          | Type           | Required | Description |
| ------------------ | -------------- | -------- | ----------- |
| `branch`           | string         | yes      | Name of the new branch to create. The commit is added to this branch. |
| `commit_message`   | string         | yes      | The commit message. |
| `content`          | string         | yes      | The file's content. |
| `file_path`        | string         | yes      | URL-encoded full path to new file. For example: `lib%2Fclass%2Erb`. |
| `id`               | integer or string | yes   | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `author_email`     | string         | no       | The commit author's email address. |
| `author_name`      | string         | no       | The commit author's name. |
| `encoding`         | string         | no       | Change encoding to `base64`. Default is `text`. |
| `execute_filemode` | boolean        | no       | Enables or disables the `execute` flag on the file. Can be `true` or `false`. |
| `start_branch`     | string         | no       | Name of the base branch to create the new branch from. |

```shell
curl --request POST \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header "Content-Type: application/json" \
  --data '{"branch": "main", "author_email": "author@example.com", "author_name": "Firstname Lastname",
            "content": "some content", "commit_message": "create a new file"}' \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fproject%2Erb"
```

Example response:

```json
{
  "file_path": "app/project.rb",
  "branch": "main"
}
```

## Update existing file in repository

Allows you to update a single file. For updating multiple files with a single request,
refer to the [commits API](commits.md#create-a-commit-with-multiple-files-and-actions).

```plaintext
PUT /projects/:id/repository/files/:file_path
```

| Attribute        | Type           | Required | Description |
| ---------------- | -------------- | -------- | ----------- |
| `branch`         | string         | yes      | Name of the new branch to create. The commit is added to this branch. |
| `commit_message` | string         | yes      | The commit message. |
| `content`        | string         | yes      | The file's content. |
| `file_path`      | string         | yes      | URL-encoded full path to new file. For example: `lib%2Fclass%2Erb`. |
| `id`             | integer or string | yes   | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths)  |
| `author_email`   | string         | no       | The commit author's email address. |
| `author_name`    | string         | no       | The commit author's name. |
| `encoding`       | string         | no       | Change encoding to `base64`. Default is `text`. |
| `execute_filemode` | boolean      | no       | Enables or disables the `execute` flag on the file. Can be `true` or `false`. |
| `last_commit_id` | string         | no       | Last known file commit ID. |
| `start_branch`   | string         | no       | Name of the base branch to create the new branch from. |

```shell
curl --request PUT \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header "Content-Type: application/json" \
  --data '{"branch": "main", "author_email": "author@example.com", "author_name": "Firstname Lastname",
       "content": "some content", "commit_message": "update file"}' \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fproject%2Erb"
```

Example response:

```json
{
  "file_path": "app/project.rb",
  "branch": "main"
}
```

If the commit fails for any reason we return a `400 Bad Request` error with a non-specific
error message. Possible causes for a failed commit include:

- The `file_path` contained `/../` (attempted directory traversal).
- The commit was empty: new file contents were identical to the current file contents.
- Someone updated the branch with `git push` while the file edit was in progress.

[GitLab Shell](https://gitlab.com/gitlab-org/gitlab-shell/) has a Boolean return code, preventing GitLab from specifying the error.

## Delete existing file in repository

Deletes a single file. To delete multiple files with a single request,
see the [commits API](commits.md#create-a-commit-with-multiple-files-and-actions).

```plaintext
DELETE /projects/:id/repository/files/:file_path
```

| Attribute        | Type           | Required | Description |
| ---------------- | -------------- | -------- | ----------- |
| `branch`         | string         | yes      | Name of the new branch to create. The commit is added to this branch. |
| `commit_message` | string         | yes      | The commit message. |
| `file_path`      | string         | yes      | URL-encoded full path to new file. For example: `lib%2Fclass%2Erb`. |
| `id`             | integer or string | yes   | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `author_email`   | string         | no       | The commit author's email address. |
| `author_name`    | string         | no       | The commit author's name. |
| `last_commit_id` | string         | no       | Last known file commit ID. |
| `start_branch`   | string         | no       | Name of the base branch to create the new branch from. |

```shell
curl --request DELETE \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header "Content-Type: application/json" \
  --data '{"branch": "main", "author_email": "author@example.com", "author_name": "Firstname Lastname",
       "commit_message": "delete file"}' \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fproject%2Erb"
```
