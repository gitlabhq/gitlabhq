# Commits API

## List repository commits

Get a list of repository commits in a project.

```
GET /projects/:id/repository/commits
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
| `ref_name` | string | no | The name of a repository branch or tag or if not given the default branch |
| `since` | string | no | Only commits after or on this date will be returned in ISO 8601 format YYYY-MM-DDTHH:MM:SSZ |
| `until` | string | no | Only commits before or on this date will be returned in ISO 8601 format YYYY-MM-DDTHH:MM:SSZ |
| `path` | string | no | The file path |
| `all` | boolean | no | Retrieve every commit from the repository |


```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/5/repository/commits"
```

Example response:

```json
[
  {
    "id": "ed899a2f4b50b4370feeea94676502b42383c746",
    "short_id": "ed899a2f4b5",
    "title": "Replace sanitize with escape once",
    "author_name": "Dmitriy Zaporozhets",
    "author_email": "dzaporozhets@sphereconsultinginc.com",
    "authored_date": "2012-09-20T11:50:22+03:00",
    "committer_name": "Administrator",
    "committer_email": "admin@example.com",
    "committed_date": "2012-09-20T11:50:22+03:00",
    "created_at": "2012-09-20T11:50:22+03:00",
    "message": "Replace sanitize with escape once",
    "parent_ids": [
      "6104942438c14ec7bd21c6cd5bd995272b3faff6"
    ]
  },
  {
    "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
    "short_id": "6104942438c",
    "title": "Sanitize for network graph",
    "author_name": "randx",
    "author_email": "dmitriy.zaporozhets@gmail.com",
    "committer_name": "Dmitriy",
    "committer_email": "dmitriy.zaporozhets@gmail.com",
    "created_at": "2012-09-20T09:06:12+03:00",
    "message": "Sanitize for network graph",
    "parent_ids": [
      "ae1d9fb46aa2b07ee9836d49862ec4e2c46fbbba"
    ]
  }
]
```

## Create a commit with multiple files and actions

> [Introduced][ce-6096] in GitLab 8.13.

Create a commit by posting a JSON payload

```
POST /projects/:id/repository/commits
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `branch` | string | yes | Name of the branch to commit into. To create a new branch, also provide `start_branch`. |
| `commit_message` | string | yes | Commit message |
| `start_branch` | string | no | Name of the branch to start the new commit from |
| `actions[]` | array | yes | An array of action hashes to commit as a batch. See the next table for what attributes it can take. |
| `author_email` | string | no | Specify the commit author's email address |
| `author_name` | string | no | Specify the commit author's name |


| `actions[]` Attribute | Type | Required | Description |
| --------------------- | ---- | -------- | ----------- |
| `action` | string | yes | The action to perform, `create`, `delete`, `move`, `update` |
| `file_path` | string | yes | Full path to the file. Ex. `lib/class.rb` |
| `previous_path` | string | no | Original full path to the file being moved. Ex. `lib/class1.rb` |
| `content` | string | no | File content, required for all except `delete`. Optional for `move` |
| `encoding` | string | no | `text` or `base64`. `text` is default. |
| `last_commit_id` | string | no | Last known file commit id. Will be only considered in update, move and delete actions. |

```bash
PAYLOAD=$(cat << 'JSON'
{
  "branch": "master",
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
    }
  ]
}
JSON
)
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --header "Content-Type: application/json" --data "$PAYLOAD" https://gitlab.example.com/api/v4/projects/1/repository/commits
```

Example response:
```json
{
  "id": "ed899a2f4b50b4370feeea94676502b42383c746",
  "short_id": "ed899a2f4b5",
  "title": "some commit message",
  "author_name": "Dmitriy Zaporozhets",
  "author_email": "dzaporozhets@sphereconsultinginc.com",
  "committer_name": "Dmitriy Zaporozhets",
  "committer_email": "dzaporozhets@sphereconsultinginc.com",
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
  "status": null
}
```

## Get a single commit

Get a specific commit identified by the commit hash or name of a branch or tag.

```
GET /projects/:id/repository/commits/:sha
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
| `sha` | string | yes | The commit hash or name of a repository branch or tag |
| `stats` | boolean | no | Include commit stats. Default is true |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/5/repository/commits/master
```

Example response:

```json
{
  "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
  "short_id": "6104942438c",
  "title": "Sanitize for network graph",
  "author_name": "randx",
  "author_email": "dmitriy.zaporozhets@gmail.com",
  "committer_name": "Dmitriy",
  "committer_email": "dmitriy.zaporozhets@gmail.com",
  "created_at": "2012-09-20T09:06:12+03:00",
  "message": "Sanitize for network graph",
  "committed_date": "2012-09-20T09:06:12+03:00",
  "authored_date": "2012-09-20T09:06:12+03:00",
  "parent_ids": [
    "ae1d9fb46aa2b07ee9836d49862ec4e2c46fbbba"
  ],
  "last_pipeline" : {
    "id": 8,
    "ref": "master",
    "sha": "2dc6aa325a317eda67812f05600bdf0fcdc70ab0"
    "status": "created"
  }
  "stats": {
    "additions": 15,
    "deletions": 10,
    "total": 25
  },
  "status": "running"
}
```

## Get references a commit is pushed to

> [Introduced][ce-15026] in GitLab 10.6

Get all references (from branches or tags) a commit is pushed to.
The pagination parameters `page` and `per_page` can be used to restrict the list of references.

```
GET /projects/:id/repository/commits/:sha/refs
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
| `sha` | string | yes | The commit hash  |
| `type` | string | no | The scope of commits. Possible values `branch`, `tag`, `all`. Default is `all`.  |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/5/repository/commits/5937ac0a7beb003549fc5fd26fc247adbce4a52e/refs?type=all"
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

## Cherry pick a commit

> [Introduced][ce-8047] in GitLab 8.15.

Cherry picks a commit to a given branch.

```
POST /projects/:id/repository/commits/:sha/cherry_pick
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
| `sha` | string | yes | The commit hash  |
| `branch` | string | yes | The name of the branch  |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --form "branch=master" "https://gitlab.example.com/api/v4/projects/5/repository/commits/master/cherry_pick"
```

Example response:

```json
{
  "id": "8b090c1b79a14f2bd9e8a738f717824ff53aebad",
  "short_id": "8b090c1b",
  "title": "Feature added",
  "author_name": "Dmitriy Zaporozhets",
  "author_email": "dmitriy.zaporozhets@gmail.com",
  "authored_date": "2016-12-12T20:10:39.000+01:00",
  "created_at": "2016-12-12T20:10:39.000+01:00",
  "committer_name": "Administrator",
  "committer_email": "admin@example.com",
  "committed_date": "2016-12-12T20:10:39.000+01:00",
  "title": "Feature added",
  "message": "Feature added\n\nSigned-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>\n",
  "parent_ids": [
    "a738f717824ff53aebad8b090c1b79a14f2bd9e8"
  ]
}
```

## Get the diff of a commit

Get the diff of a commit in a project.

```
GET /projects/:id/repository/commits/:sha/diff
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
| `sha` | string | yes | The commit hash or name of a repository branch or tag |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/5/repository/commits/master/diff"
```

Example response:

```json
[
  {
    "diff": "--- a/doc/update/5.4-to-6.0.md\n+++ b/doc/update/5.4-to-6.0.md\n@@ -71,6 +71,8 @@\n sudo -u git -H bundle exec rake migrate_keys RAILS_ENV=production\n sudo -u git -H bundle exec rake migrate_inline_notes RAILS_ENV=production\n \n+sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production\n+\n ```\n \n ### 6. Update config files",
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

```
GET /projects/:id/repository/commits/:sha/comments
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
| `sha` | string | yes | The commit hash or name of a repository branch or tag |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/5/repository/commits/master/comments"
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

In order to post a comment in a particular line of a particular file, you must
specify the full commit SHA, the `path`, the `line` and `line_type` should be
`new`.

The comment will be added at the end of the last commit if at least one of the
cases below is valid:

- the `sha` is instead a branch or a tag and the `line` or `path` are invalid
- the `line` number is invalid (does not exist)
- the `path` is invalid (does not exist)

In any of the above cases, the response of `line`, `line_type` and `path` is
set to `null`.

```
POST /projects/:id/repository/commits/:sha/comments
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
| `sha`       | string  | yes | The commit SHA or name of a repository branch or tag |
| `note`      | string  | yes | The text of the comment |
| `path`      | string  | no  | The file path relative to the repository |
| `line`      | integer | no  | The line number where the comment should be placed |
| `line_type` | string  | no  | The line type. Takes `new` or `old` as arguments |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --form "note=Nice picture man\!" --form "path=dudeism.md" --form "line=11" --form "line_type=new" https://gitlab.example.com/api/v4/projects/17/repository/commits/18f3e63d05582537db6d183d9d557be09e1f90c8/comments
```

Example response:

```json
{
   "author" : {
      "web_url" : "https://gitlab.example.com/thedude",
      "avatar_url" : "https://gitlab.example.com/uploads/user/avatar/28/The-Big-Lebowski-400-400.png",
      "username" : "thedude",
      "state" : "active",
      "name" : "Jeff Lebowski",
      "id" : 28
   },
   "created_at" : "2016-01-19T09:44:55.600Z",
   "line_type" : "new",
   "path" : "dudeism.md",
   "line" : 11,
   "note" : "Nice picture man!"
}
```

## Commit status

Since GitLab 8.1, this is the new commit status API.

### List the statuses of a commit

List the statuses of a commit in a project.
The pagination parameters `page` and `per_page` can be used to restrict the list of references.

```
GET /projects/:id/repository/commits/:sha/statuses
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
| `sha`     | string  | yes | The commit SHA
| `ref`     | string  | no  | The name of a repository branch or tag or, if not given, the default branch
| `stage`   | string  | no  | Filter by [build stage](../ci/yaml/README.md#stages), e.g., `test`
| `name`    | string  | no  | Filter by [job name](../ci/yaml/README.md#jobs), e.g., `bundler:audit`
| `all`     | boolean | no  | Return all statuses, not only the latest ones

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/17/repository/commits/18f3e63d05582537db6d183d9d557be09e1f90c8/statuses
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
         "username" : "thedude",
         "state" : "active",
         "web_url" : "https://gitlab.example.com/thedude",
         "avatar_url" : "https://gitlab.example.com/uploads/user/avatar/28/The-Big-Lebowski-400-400.png",
         "id" : 28,
         "name" : "Jeff Lebowski"
      },
      "description" : null,
      "sha" : "18f3e63d05582537db6d183d9d557be09e1f90c8",
      "target_url" : "https://gitlab.example.com/thedude/gitlab-ce/builds/91",
      "finished_at" : null,
      "id" : 91,
      "ref" : "master"
   },
   {
      "started_at" : null,
      "name" : "flay",
      "allow_failure" : false,
      "status" : "pending",
      "created_at" : "2016-01-19T08:40:25.832Z",
      "target_url" : "https://gitlab.example.com/thedude/gitlab-ce/builds/90",
      "id" : 90,
      "finished_at" : null,
      "ref" : "master",
      "sha" : "18f3e63d05582537db6d183d9d557be09e1f90c8",
      "author" : {
         "id" : 28,
         "name" : "Jeff Lebowski",
         "username" : "thedude",
         "web_url" : "https://gitlab.example.com/thedude",
         "state" : "active",
         "avatar_url" : "https://gitlab.example.com/uploads/user/avatar/28/The-Big-Lebowski-400-400.png"
      },
      "description" : null
   },

   ...
]
```

### Post the build status to a commit

Adds or updates a build status of a commit.

```
POST /projects/:id/statuses/:sha
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
| `sha`     | string  | yes   | The commit SHA
| `state`   | string  | yes   | The state of the status. Can be one of the following: `pending`, `running`, `success`, `failed`, `canceled`
| `ref`     | string  | no    | The `ref` (branch or tag) to which the status refers
| `name` or `context` | string  | no | The label to differentiate this status from the status of other systems. Default value is `default`
| `target_url` |  string  | no  | The target URL to associate with this status
| `description` | string  | no  | The short description of the status
| `coverage` | float  | no    | The total code coverage

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/17/statuses/18f3e63d05582537db6d183d9d557be09e1f90c8?state=success"
```

Example response:

```json
{
   "author" : {
      "web_url" : "https://gitlab.example.com/thedude",
      "name" : "Jeff Lebowski",
      "avatar_url" : "https://gitlab.example.com/uploads/user/avatar/28/The-Big-Lebowski-400-400.png",
      "username" : "thedude",
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

## List Merge Requests associated with a commit

Get a list of Merge Requests related to the specified commit.

```
GET /projects/:id/repository/commits/:sha/merge_requests
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
| `sha`     | string  | yes   | The commit SHA


```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/5/repository/commits/af5b13261899fb2c0db30abdd0af8b07cb44fdc5/merge_requests"
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
      "target_branch":"master",
      "source_branch":"test-branch",
      "upvotes":0,
      "downvotes":0,
      "author" : {
        "web_url" : "https://gitlab.example.com/thedude",
        "name" : "Jeff Lebowski",
        "avatar_url" : "https://gitlab.example.com/uploads/user/avatar/28/The-Big-Lebowski-400-400.png",
        "username" : "thedude",
        "state" : "active",
        "id" : 28
      },
      "assignee":null,
      "source_project_id":35,
      "target_project_id":35,
      "labels":[ ],
      "work_in_progress":false,
      "milestone":null,
      "merge_when_pipeline_succeeds":false,
      "merge_status":"can_be_merged",
      "sha":"af5b13261899fb2c0db30abdd0af8b07cb44fdc5",
      "merge_commit_sha":null,
      "user_notes_count":0,
      "discussion_locked":null,
      "should_remove_source_branch":null,
      "force_remove_source_branch":false,
      "web_url":"http://https://gitlab.example.com/root/test-project/merge_requests/1",
      "time_stats":{
         "time_estimate":0,
         "total_time_spent":0,
         "human_time_estimate":null,
         "human_total_time_spent":null
      }
   }
]
```

[ce-6096]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/6096 "Multi-file commit"
[ce-8047]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8047
[ce-15026]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/15026
