---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Documentation for the REST API for Git commits in GitLab."
title: Commits API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This API operates on [repository commits](https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository). Read more about [GitLab-specific information](../user/project/repository/_index.md#commit-changes-to-a-repository) for commits.

## Responses

Some date fields in responses from this API are, or can appear to be, duplicated
information:

- The `created_at` field exists solely for consistency with other GitLab APIs. It
  is always identical to the `committed_date` field.
- The `committed_date` and `authored_date` fields are generated from different sources,
  and may not be identical.

## List repository commits

> - Commits by author [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114417) in GitLab 15.10.

Get a list of repository commits in a project.

```plaintext
GET /projects/:id/repository/commits
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `ref_name` | string | no | The name of a repository branch, tag or revision range, or if not given the default branch |
| `since` | string | no | Only commits after or on this date are returned in ISO 8601 format `YYYY-MM-DDTHH:MM:SSZ` |
| `until` | string | no | Only commits before or on this date are returned in ISO 8601 format `YYYY-MM-DDTHH:MM:SSZ` |
| `path` | string | no | The file path |
| `author` | string | no | Search commits by commit author.|
| `all` | boolean | no | Retrieve every commit from the repository |
| `with_stats` | boolean | no | Stats about each commit are added to the response |
| `first_parent` | boolean | no | Follow only the first parent commit upon seeing a merge commit |
| `order` | string | no | List commits in order. Possible values: `default`, [`topo`](https://git-scm.com/docs/git-log#Documentation/git-log.txt---topo-order). Defaults to `default`, the commits are shown in reverse chronological order. |
| `trailers` | boolean | no | Parse and include [Git trailers](https://git-scm.com/docs/git-interpret-trailers) for every commit |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits"
```

Example response:

```json
[
  {
    "id": "ed899a2f4b50b4370feeea94676502b42383c746",
    "short_id": "ed899a2f4b5",
    "title": "Replace sanitize with escape once",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "authored_date": "2021-09-20T11:50:22.001+00:00",
    "committer_name": "Administrator",
    "committer_email": "admin@example.com",
    "committed_date": "2021-09-20T11:50:22.001+00:00",
    "created_at": "2021-09-20T11:50:22.001+00:00",
    "message": "Replace sanitize with escape once",
    "parent_ids": [
      "6104942438c14ec7bd21c6cd5bd995272b3faff6"
    ],
    "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/ed899a2f4b50b4370feeea94676502b42383c746",
    "trailers": {},
    "extended_trailers": {}
  },
  {
    "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
    "short_id": "6104942438c",
    "title": "Sanitize for network graph",
    "author_name": "randx",
    "author_email": "user@example.com",
    "committer_name": "ExampleName",
    "committer_email": "user@example.com",
    "created_at": "2021-09-20T09:06:12.201+00:00",
    "message": "Sanitize for network graph\nCc: John Doe <johndoe@gitlab.com>\nCc: Jane Doe <janedoe@gitlab.com>",
    "parent_ids": [
      "ae1d9fb46aa2b07ee9836d49862ec4e2c46fbbba"
    ],
    "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/ed899a2f4b50b4370feeea94676502b42383c746",
    "trailers": { "Cc": "Jane Doe <janedoe@gitlab.com>" },
    "extended_trailers": { "Cc": ["John Doe <johndoe@gitlab.com>", "Jane Doe <janedoe@gitlab.com>"] }
  }
]
```

## Create a commit with multiple files and actions

Create a commit by posting a JSON payload

```plaintext
POST /projects/:id/repository/commits
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `branch` | string | yes | Name of the branch to commit into. To create a new branch, also provide either `start_branch` or `start_sha`, and optionally `start_project`. |
| `commit_message` | string | yes | Commit message |
| `start_branch` | string | no | Name of the branch to start the new branch from |
| `start_sha` | string | no | SHA of the commit to start the new branch from |
| `start_project` | integer/string | no | The project ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) to start the new branch from. Defaults to the value of `id`. |
| `actions[]` | array | yes | An array of action hashes to commit as a batch. See the next table for what attributes it can take. |
| `author_email` | string | no | Specify the commit author's email address |
| `author_name` | string | no | Specify the commit author's name |
| `stats` | boolean | no | Include commit stats. Default is true |
| `force` | boolean | no | When `true` overwrites the target branch with a new commit based on the `start_branch` or `start_sha` |

| `actions[]` Attribute | Type    | Required | Description |
|-----------------------|---------|----------|-------------|
| `action`              | string  | yes      | The action to perform: `create`, `delete`, `move`, `update`, or `chmod`. |
| `file_path`           | string  | yes      | Full path to the file. For example: `lib/class.rb`. |
| `previous_path`       | string  | no       | Original full path to the file being moved. For example `lib/class1.rb`. Only considered for `move` action. |
| `content`             | string  | no       | File content, required for all except `delete`, `chmod`, and `move`. Move actions that do not specify `content` preserve the existing file content, and any other value of `content` overwrites the file content. |
| `encoding`            | string  | no       | `text` or `base64`. `text` is default. |
| `last_commit_id`      | string  | no       | Last known file commit ID. Only considered in update, move, and delete actions. |
| `execute_filemode`    | boolean | no       | When `true/false` enables/disables the execute flag on the file. Only considered for `chmod` action. |

```shell
PAYLOAD=$(cat << 'JSON'
{
  "branch": "main",
  "commit_message": "some commit message",
  "actions": [
    {
      "action": "create",
      "file_path": "foo/bar",
      "content": "some content"
    },
    {
      "action": "delete",
      "file_path": "foo/bar2"
    },
    {
      "action": "move",
      "file_path": "foo/bar3",
      "previous_path": "foo/bar4",
      "content": "some content"
    },
    {
      "action": "update",
      "file_path": "foo/bar5",
      "content": "new content"
    },
    {
      "action": "chmod",
      "file_path": "foo/bar5",
      "execute_filemode": true
    }
  ]
}
JSON
)
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data "$PAYLOAD" \
  --url "https://gitlab.example.com/api/v4/projects/1/repository/commits"
```

Example response:

```json
{
  "id": "ed899a2f4b50b4370feeea94676502b42383c746",
  "short_id": "ed899a2f4b5",
  "title": "some commit message",
  "author_name": "Example User",
  "author_email": "user@example.com",
  "committer_name": "Example User",
  "committer_email": "user@example.com",
  "created_at": "2016-09-20T09:26:24.000-07:00",
  "message": "some commit message",
  "parent_ids": [
    "ae1d9fb46aa2b07ee9836d49862ec4e2c46fbbba"
  ],
  "committed_date": "2016-09-20T09:26:24.000-07:00",
  "authored_date": "2016-09-20T09:26:24.000-07:00",
  "stats": {
    "additions": 2,
    "deletions": 2,
    "total": 4
  },
  "status": null,
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/ed899a2f4b50b4370feeea94676502b42383c746"
}
```

GitLab supports [form encoding](rest/_index.md#array-and-hash-types). The following is an example using Commit API with form encoding:

```shell
curl --request POST \
     --form "branch=main" \
     --form "commit_message=some commit message" \
     --form "start_branch=main" \
     --form "actions[][action]=create" \
     --form "actions[][file_path]=foo/bar" \
     --form "actions[][content]=</path/to/local.file" \
     --form "actions[][action]=delete" \
     --form "actions[][file_path]=foo/bar2" \
     --form "actions[][action]=move" \
     --form "actions[][file_path]=foo/bar3" \
     --form "actions[][previous_path]=foo/bar4" \
     --form "actions[][content]=</path/to/local1.file" \
     --form "actions[][action]=update" \
     --form "actions[][file_path]=foo/bar5" \
     --form "actions[][content]=</path/to/local2.file" \
     --form "actions[][action]=chmod" \
     --form "actions[][file_path]=foo/bar5" \
     --form "actions[][execute_filemode]=true" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/repository/commits"
```

## Get a single commit

Get a specific commit identified by the commit hash or name of a branch or tag.

```plaintext
GET /projects/:id/repository/commits/:sha
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `sha` | string | yes | The commit hash or name of a repository branch or tag |
| `stats` | boolean | no | Include commit stats. Default is true |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/main"
```

Example response:

```json
{
  "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
  "short_id": "6104942438c",
  "title": "Sanitize for network graph",
  "author_name": "randx",
  "author_email": "user@example.com",
  "committer_name": "Dmitriy",
  "committer_email": "user@example.com",
  "created_at": "2021-09-20T09:06:12.300+03:00",
  "message": "Sanitize for network graph",
  "committed_date": "2021-09-20T09:06:12.300+03:00",
  "authored_date": "2021-09-20T09:06:12.420+03:00",
  "parent_ids": [
    "ae1d9fb46aa2b07ee9836d49862ec4e2c46fbbba"
  ],
  "last_pipeline" : {
    "id": 8,
    "ref": "main",
    "sha": "2dc6aa325a317eda67812f05600bdf0fcdc70ab0",
    "status": "created"
  },
  "stats": {
    "additions": 15,
    "deletions": 10,
    "total": 25
  },
  "status": "running",
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/6104942438c14ec7bd21c6cd5bd995272b3faff6"
}
```

## Get references a commit is pushed to

Get all references (from branches or tags) a commit is pushed to.
The pagination parameters `page` and `per_page` can be used to restrict the list of references.

```plaintext
GET /projects/:id/repository/commits/:sha/refs
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `sha` | string | yes | The commit hash  |
| `type` | string | no | The scope of commits. Possible values `branch`, `tag`, `all`. Default is `all`.  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/5937ac0a7beb003549fc5fd26fc247adbce4a52e/refs?type=all"
```

Example response:

```json
[
  {"type": "branch", "name": "'test'"},
  {"type": "branch", "name": "add-balsamiq-file"},
  {"type": "branch", "name": "wip"},
  {"type": "tag", "name": "v1.1.0"}
 ]

```

## Get the sequence of a commit

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/438151) in GitLab 16.9.

Get the sequence number of a commit in a project by following the parent links from the given commit.

This API provides essentially the same features as the `git rev-list --count` command for a given commit SHA.

```plaintext
GET /projects/:id/repository/commits/:sha/sequence
```

Parameters:

| Attribute      | Type           | Required | Description |
| -------------- | -------------- | -------- | ----------- |
| `id`           | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `sha`          | string         | yes      | The commit hash. |
| `first_parent` | boolean        | no       | Follow only the first parent commit upon seeing a merge commit. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/5937ac0a7beb003549fc5fd26fc247adbce4a52e/sequence"
```

Example response:

```json
{
  "count": 632
}
```

## Cherry-pick a commit

Cherry-picks a commit to a given branch.

```plaintext
POST /projects/:id/repository/commits/:sha/cherry_pick
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `sha` | string | yes | The commit hash  |
| `branch` | string | yes | The name of the branch  |
| `dry_run` | boolean | no | Does not commit any changes. Default is false. |
| `message` | string | no | A custom commit message to use for the new commit. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "branch=main" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/main/cherry_pick"
```

Example response:

```json
{
  "id": "8b090c1b79a14f2bd9e8a738f717824ff53aebad",
  "short_id": "8b090c1b",
  "author_name": "Example User",
  "author_email": "user@example.com",
  "authored_date": "2016-12-12T20:10:39.000+01:00",
  "created_at": "2016-12-12T20:10:39.000+01:00",
  "committer_name": "Administrator",
  "committer_email": "admin@example.com",
  "committed_date": "2016-12-12T20:10:39.000+01:00",
  "title": "Feature added",
  "message": "Feature added\n\nSigned-off-by: Example User <user@example.com>\n",
  "parent_ids": [
    "a738f717824ff53aebad8b090c1b79a14f2bd9e8"
  ],
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/8b090c1b79a14f2bd9e8a738f717824ff53aebad"
}
```

In the event of a failed cherry-pick, the response provides context about
why:

```json
{
  "message": "Sorry, we cannot cherry-pick this commit automatically. This commit may already have been cherry-picked, or a more recent commit may have updated some of its content.",
  "error_code": "empty"
}
```

In this case, the cherry-pick failed because the changeset was empty and likely
indicates that the commit already exists in the target branch. The other
possible error code is `conflict`, which indicates that there was a merge
conflict.

When `dry_run` is enabled, the server attempts to apply the cherry-pick _but
not actually commit any resulting changes_. If the cherry-pick applies cleanly,
the API responds with `200 OK`:

```json
{
  "dry_run": "success"
}
```

In the event of a failure, an error displays that is identical to a failure without
dry run.

## Revert a commit

Reverts a commit in a given branch.

```plaintext
POST /projects/:id/repository/commits/:sha/revert
```

Parameters:

| Attribute | Type           | Required | Description                                                                     |
| --------- | ----           | -------- | -----------                                                                     |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `sha`     | string         | yes      | Commit SHA to revert                                                            |
| `branch`  | string         | yes      | Target branch name                                                              |
| `dry_run` | boolean        | no       | Does not commit any changes. Default is false. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "branch=main" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/a738f717824ff53aebad8b090c1b79a14f2bd9e8/revert"
```

Example response:

```json
{
  "id":"8b090c1b79a14f2bd9e8a738f717824ff53aebad",
  "short_id": "8b090c1b",
  "title":"Revert \"Feature added\"",
  "created_at":"2018-11-08T15:55:26.000Z",
  "parent_ids":["a738f717824ff53aebad8b090c1b79a14f2bd9e8"],
  "message":"Revert \"Feature added\"\n\nThis reverts commit a738f717824ff53aebad8b090c1b79a14f2bd9e8",
  "author_name":"Administrator",
  "author_email":"admin@example.com",
  "authored_date":"2018-11-08T15:55:26.000Z",
  "committer_name":"Administrator",
  "committer_email":"admin@example.com",
  "committed_date":"2018-11-08T15:55:26.000Z",
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/commit/8b090c1b79a14f2bd9e8a738f717824ff53aebad"
}
```

In the event of a failed revert, the response provides context about why:

```json
{
  "message": "Sorry, we cannot revert this commit automatically. This commit may already have been reverted, or a more recent commit may have updated some of its content.",
  "error_code": "conflict"
}
```

In this case, the revert failed because the attempted revert generated a merge
conflict. The other possible error code is `empty`, which indicates that the
changeset was empty, likely due to the change having already been reverted.

When `dry_run` is enabled, the server attempts to apply the revert _but not
actually commit any resulting changes_. If the revert applies cleanly, the API
responds with `200 OK`:

```json
{
  "dry_run": "success"
}
```

In the event of a failure, an error displays that is identical to a failure without
dry run.

## Get the diff of a commit

Get the diff of a commit in a project.

```plaintext
GET /projects/:id/repository/commits/:sha/diff
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `sha` | string | yes | The commit hash or name of a repository branch or tag |
| `unidiff` | boolean | no | Present diffs in the [unified diff](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html) format. Default is false. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610) in GitLab 16.5. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/main/diff"
```

Example response:

```json
[
  {
    "diff": "@@ -71,6 +71,8 @@\n sudo -u git -H bundle exec rake migrate_keys RAILS_ENV=production\n sudo -u git -H bundle exec rake migrate_inline_notes RAILS_ENV=production\n \n+sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production\n+\n ```\n \n ### 6. Update config files",
    "new_path": "doc/update/5.4-to-6.0.md",
    "old_path": "doc/update/5.4-to-6.0.md",
    "a_mode": null,
    "b_mode": "100644",
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false
  }
]
```

## Get the comments of a commit

Get the comments of a commit in a project.

```plaintext
GET /projects/:id/repository/commits/:sha/comments
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `sha` | string | yes | The commit hash or name of a repository branch or tag |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/main/comments"
```

Example response:

```json
[
  {
    "note": "this code is really nice",
    "author": {
      "id": 11,
      "username": "admin",
      "email": "admin@local.host",
      "name": "Administrator",
      "state": "active",
      "created_at": "2014-03-06T08:17:35.000Z"
    }
  }
]
```

## Post comment to commit

Adds a comment to a commit.

To post a comment in a particular line of a particular file, you must specify
the full commit SHA, the `path`, the `line`, and `line_type` should be `new`.

The comment is added at the end of the last commit if at least one of the
cases below is valid:

- the `sha` is instead a branch or a tag and the `line` or `path` are invalid
- the `line` number is invalid (does not exist)
- the `path` is invalid (does not exist)

In any of the above cases, the response of `line`, `line_type` and `path` is
set to `null`.

For other approaches to commenting on a merge request, see
[Create new merge request note](notes.md#create-new-merge-request-note) in the Notes API,
and [Create a new thread in the merge request diff](discussions.md#create-a-new-thread-in-the-merge-request-diff)
in the Discussions API.

```plaintext
POST /projects/:id/repository/commits/:sha/comments
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `sha`       | string  | yes | The commit SHA or name of a repository branch or tag |
| `note`      | string  | yes | The text of the comment |
| `path`      | string  | no  | The file path relative to the repository |
| `line`      | integer | no  | The line number where the comment should be placed |
| `line_type` | string  | no  | The line type. Takes `new` or `old` as arguments |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "note=Nice picture\!" \
  --form "path=README.md" \
  --form "line=11" \
  --form "line_type=new" \
  --url "https://gitlab.example.com/api/v4/projects/17/repository/commits/18f3e63d05582537db6d183d9d557be09e1f90c8/comments"
```

Example response:

```json
{
   "author" : {
      "web_url" : "https://gitlab.example.com/janedoe",
      "avatar_url" : "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png",
      "username" : "janedoe",
      "state" : "active",
      "name" : "Jane Doe",
      "id" : 28
   },
   "created_at" : "2016-01-19T09:44:55.600Z",
   "line_type" : "new",
   "path" : "README.md",
   "line" : 11,
   "note" : "Nice picture!"
}
```

## Get the discussions of a commit

Get the discussions of a commit in a project.

```plaintext
GET /projects/:id/repository/commits/:sha/discussions
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `sha`     | string | yes | The commit hash or name of a repository branch or tag |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/4604744a1c64de00ff62e1e8a6766919923d2b41/discussions"
```

Example response:

```json
[
  {
    "id": "4604744a1c64de00ff62e1e8a6766919923d2b41",
    "individual_note": true,
    "notes": [
      {
        "id": 334686748,
        "type": null,
        "body": "Nice piece of code!",
        "attachment": null,
        "author" : {
          "id" : 28,
          "name" : "Jane Doe",
          "username" : "janedoe",
          "web_url" : "https://gitlab.example.com/janedoe",
          "state" : "active",
          "avatar_url" : "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png"
        },
        "created_at": "2020-04-30T18:48:11.432Z",
        "updated_at": "2020-04-30T18:48:11.432Z",
        "system": false,
        "noteable_id": null,
        "noteable_type": "Commit",
        "resolvable": false,
        "confidential": null,
        "noteable_iid": null,
        "commands_changes": {}
      }
    ]
  }
]

```

## Commit status

The commit status API for use with GitLab.

### List the statuses of a commit

> - `pipeline_id`, `order_by`, and `sort` fields [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176142) in GitLab 17.9.

List the statuses of a commit in a project.
The pagination parameters `page` and `per_page` can be used to restrict the list of references.

```plaintext
GET /projects/:id/repository/commits/:sha/statuses
```

| Attribute     | Type           | Required | Description                                                                          |
|---------------|----------------| -------- |--------------------------------------------------------------------------------------|
| `id`          | integer/string | Yes | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).          |
| `sha`         | string         | Yes | Hash of the commit.                                                                      |
| `ref`         | string         | No  | Name of the branch or tag. Default is the default branch.          |
| `stage`       | string         | No  | Filter statuses by [build stage](../ci/yaml/_index.md#stages). For example, `test`.             |
| `name`        | string         | No  | Filter statuses by [job name](../ci/yaml/_index.md#job-keywords). For example, `bundler:audit`. |
| `pipeline_id` | integer        | No  | Filter statuses by pipeline ID. For example, `1234`.                                            |
| `order_by`    | string         | No  | Values for sorting statuses. Valid values are `id` and `pipeline_id`. Default is `id`.                    |
| `sort`        | string         | No  | Sort statuses in ascending or descending order. Valid values are `asc` and `desc`. Default is `asc`.                  |
| `all`         | boolean        | No  | Include all statuses instead of latest only. Default is `false`.                                       |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/17/repository/commits/18f3e63d05582537db6d183d9d557be09e1f90c8/statuses"
```

Example response:

```json
[
   ...

   {
      "status" : "pending",
      "created_at" : "2016-01-19T08:40:25.934Z",
      "started_at" : null,
      "name" : "bundler:audit",
      "allow_failure" : true,
      "author" : {
         "username" : "janedoe",
         "state" : "active",
         "web_url" : "https://gitlab.example.com/janedoe",
         "avatar_url" : "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png",
         "id" : 28,
         "name" : "Jane Doe"
      },
      "description" : null,
      "sha" : "18f3e63d05582537db6d183d9d557be09e1f90c8",
      "target_url" : "https://gitlab.example.com/janedoe/gitlab-foss/builds/91",
      "finished_at" : null,
      "id" : 91,
      "ref" : "main"
   },
   {
      "started_at" : null,
      "name" : "test",
      "allow_failure" : false,
      "status" : "pending",
      "created_at" : "2016-01-19T08:40:25.832Z",
      "target_url" : "https://gitlab.example.com/janedoe/gitlab-foss/builds/90",
      "id" : 90,
      "finished_at" : null,
      "ref" : "main",
      "sha" : "18f3e63d05582537db6d183d9d557be09e1f90c8",
      "author" : {
         "id" : 28,
         "name" : "Jane Doe",
         "username" : "janedoe",
         "web_url" : "https://gitlab.example.com/janedoe",
         "state" : "active",
         "avatar_url" : "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png"
      },
      "description" : null
   },

   ...
]
```

### Set the pipeline status of a commit

Add or update the pipeline status of a commit. If the commit is associated with a merge request,
the API call must target the commit in the merge request's source branch.

```plaintext
POST /projects/:id/statuses/:sha
```

| Attribute | Type | Required | Description                                                                                                           |
| --------- | ---- | -------- |-----------------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths)                                           |
| `sha`     | string  | yes   | The commit SHA                                                                                                        |
| `state`   | string  | yes   | The state of the status. Can be one of the following: `pending`, `running`, `success`, `failed`, `canceled`, `skipped` |
| `ref`     | string  | no    | The `ref` (branch or tag) to which the status refers. Must be 255 characters or fewer.                                                                  |
| `name` or `context` | string  | no | The label to differentiate this status from the status of other systems. Default value is `default`                   |
| `target_url` |  string  | no  | The target URL to associate with this status. Must be 255 characters or fewer.                                                                          |
| `description` | string  | no  | The short description of the status. Must be 255 characters or fewer.                                                                                   |
| `coverage` | float  | no    | The total code coverage                                                                                               |
| `pipeline_id` |  integer  | no  | The ID of the pipeline to set status. Use in case of several pipeline on same SHA.                                    |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/17/statuses/18f3e63d05582537db6d183d9d557be09e1f90c8?state=success"
```

Example response:

```json
{
   "author" : {
      "web_url" : "https://gitlab.example.com/janedoe",
      "name" : "Jane Doe",
      "avatar_url" : "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png",
      "username" : "janedoe",
      "state" : "active",
      "id" : 28
   },
   "name" : "default",
   "sha" : "18f3e63d05582537db6d183d9d557be09e1f90c8",
   "status" : "success",
   "coverage": 100.0,
   "description" : null,
   "id" : 93,
   "target_url" : null,
   "ref" : null,
   "started_at" : null,
   "created_at" : "2016-01-19T09:05:50.355Z",
   "allow_failure" : false,
   "finished_at" : "2016-01-19T09:05:50.365Z"
}
```

## List merge requests associated with a commit

Returns information about the merge request that originally introduced a specific commit.

```plaintext
GET /projects/:id/repository/commits/:sha/merge_requests
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `sha`     | string  | yes   | The commit SHA |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/commits/af5b13261899fb2c0db30abdd0af8b07cb44fdc5/merge_requests"
```

Example response:

```json
[
   {
      "id":45,
      "iid":1,
      "project_id":35,
      "title":"Add new file",
      "description":"",
      "state":"opened",
      "created_at":"2018-03-26T17:26:30.916Z",
      "updated_at":"2018-03-26T17:26:30.916Z",
      "target_branch":"main",
      "source_branch":"test-branch",
      "upvotes":0,
      "downvotes":0,
      "author" : {
        "web_url" : "https://gitlab.example.com/janedoe",
        "name" : "Jane Doe",
        "avatar_url" : "https://gitlab.example.com/uploads/user/avatar/28/jane-doe-400-400.png",
        "username" : "janedoe",
        "state" : "active",
        "id" : 28
      },
      "assignee":null,
      "source_project_id":35,
      "target_project_id":35,
      "labels":[ ],
      "draft":false,
      "work_in_progress":false,
      "milestone":null,
      "merge_when_pipeline_succeeds":false,
      "merge_status":"can_be_merged",
      "sha":"af5b13261899fb2c0db30abdd0af8b07cb44fdc5",
      "merge_commit_sha":null,
      "squash_commit_sha":null,
      "user_notes_count":0,
      "discussion_locked":null,
      "should_remove_source_branch":null,
      "force_remove_source_branch":false,
      "web_url":"https://gitlab.example.com/root/test-project/merge_requests/1",
      "time_stats":{
         "time_estimate":0,
         "total_time_spent":0,
         "human_time_estimate":null,
         "human_total_time_spent":null
      }
   }
]
```

## Get signature of a commit

Get the [signature from a commit](../user/project/repository/signed_commits/_index.md),
if it is signed. For unsigned commits, it results in a 404 response.

```plaintext
GET /projects/:id/repository/commits/:sha/signature
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `sha` | string | yes | The commit hash or name of a repository branch or tag |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/repository/commits/da738facbc19eb2fc2cef57c49be0e6038570352/signature"
```

Example response if commit is GPG signed:

```json
{
  "signature_type": "PGP",
  "verification_status": "verified",
  "gpg_key_id": 1,
  "gpg_key_primary_keyid": "8254AAB3FBD54AC9",
  "gpg_key_user_name": "John Doe",
  "gpg_key_user_email": "johndoe@example.com",
  "gpg_key_subkey_id": null,
  "commit_source": "gitaly"
}
```

Example response if commit is signed with SSH:

```json
{
  "signature_type": "SSH",
  "verification_status": "verified",
  "key": {
    "id": 11,
    "title": "Key",
    "created_at": "2023-05-08T09:12:38.503Z",
    "expires_at": "2024-05-07T00:00:00.000Z",
    "key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILZzYDq6DhLp3aX84DGIV3F6Vf+Ae4yCTTz7RnqMJOlR MyKey)",
    "usage_type": "auth_and_signing"
  },
  "commit_source": "gitaly"
}
```

Example response if commit is X.509 signed:

```json
{
  "signature_type": "X509",
  "verification_status": "unverified",
  "x509_certificate": {
    "id": 1,
    "subject": "CN=gitlab@example.org,OU=Example,O=World",
    "subject_key_identifier": "BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC",
    "email": "gitlab@example.org",
    "serial_number": 278969561018901340486471282831158785578,
    "certificate_status": "good",
    "x509_issuer": {
      "id": 1,
      "subject": "CN=PKI,OU=Example,O=World",
      "subject_key_identifier": "AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB",
      "crl_url": "http://example.com/pki.crl"
    }
  },
  "commit_source": "gitaly"
}
```

Example response if commit is unsigned:

```json
{
  "message": "404 GPG Signature Not Found"
}
```
