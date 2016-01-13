# Commits API

## List repository commits

Get a list of repository commits in a project.

```
GET /projects/:id/repository/commits
```

| Attribute   | Type    | required | Description             |
|-------------|---------|----------|-------------------------|
| `id`        | integer | yes      | The ID of a project     |
| `ref_name`  | string  | no       | The name of a repository branch or tag or if not given the default branch |

```
curl -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/repository/commits"
```

```json
[
  {
    "id": "ed899a2f4b50b4370feeea94676502b42383c746",
    "short_id": "ed899a2f4b5",
    "title": "Replace sanitize with escape once",
    "author_name": "Dmitriy Zaporozhets",
    "author_email": "dzaporozhets@sphereconsultinginc.com",
    "created_at": "2012-09-20T11:50:22+03:00",
    "message": "Replace sanitize with escape once",
    "allow_failure": false
  },
  {
    "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
    "short_id": "6104942438c",
    "title": "Sanitize for network graph",
    "author_name": "randx",
    "author_email": "dmitriy.zaporozhets@gmail.com",
    "created_at": "2012-09-20T09:06:12+03:00",
    "message": "Sanitize for network graph",
    "allow_failure": false
  }
]
```

## Get a single commit

Get a specific commit identified by the commit hash or name of a branch or tag.

```
GET /projects/:id/repository/commits/:sha
```

| Attribute | Type    | required | Description             |
|-----------|---------|----------|-------------------------|
| `id`      | integer | yes      | The ID of a project     |
| `sha`     | string  | yes      | The commit SHA          |

```
curl -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/repository/commits/6104942438c14ec7bd21c6cd5bd995272b3faff6"
```

```json
{
  "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
  "short_id": "6104942438c",
  "title": "Sanitize for network graph",
  "author_name": "randx",
  "author_email": "dmitriy.zaporozhets@gmail.com",
  "created_at": "2012-09-20T09:06:12+03:00",
  "message": "Sanitize for network graph",
  "committed_date": "2012-09-20T09:06:12+03:00",
  "authored_date": "2012-09-20T09:06:12+03:00",
  "parent_ids": [
    "ae1d9fb46aa2b07ee9836d49862ec4e2c46fbbba"
  ],
  "status": "running",
  "coverage": null,
  "duration": 2,
  "started_at": "2015-12-24T17:54:09.744Z",
  "finished_at": "2016-01-11T10:14:09.526Z"
}
```

## Get the diff of a commit

Get the diff of a commit in a project.

```
GET /projects/:id/repository/commits/:sha/diff
```

| Attribute | Type    | required | Description             |
|-----------|---------|----------|-------------------------|
| `id`      | integer | yes      | The ID of a project     |
| `sha`     | string  | yes      | The commit SHA          |

```
curl -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/repository/commits/6104942438c14ec7bd21c6cd5bd995272b3faff6/diff"
```

```json
[
  {
    "diff": "--- a/doc/update/5.4-to-6.0.md\n+++ b/doc/update/5.4-to-6.0.md\n@@ -71,6 +71,8 @@\n sudo -u git -H bundle exec rake migrate_keys RAILS_ENV=production\n sudo -u git -H bundle exec rake migrate_inline_notes RAILS_ENV=production\n \n+sudo -u git -H bundle exec rake assets:precompile RAILS_ENV=production\n+\n ```\n \n ### 6. Update config files",
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

| Attribute | Type    | required | Description             |
|-----------|---------|----------|-------------------------|
| `id`      | integer | yes      | The ID of a project     |
| `sha`     | string  | yes      | The commit SHA          |

```
curl -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/repository/commits/6104942438c14ec7bd21c6cd5bd995272b3faff6/comments"
```

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

Adds a comment to a commit. Optionally you can post comments on a specific line of a commit. Therefor both `path`, `line_new` and `line_old` are required.

```
POST /projects/:id/repository/commits/:sha/comments
```

| Attribute    | Type    | required | Description             |
|--------------|---------|----------|-------------------------|
| `id`         | integer | yes      | The ID of a project     |
| `sha`        | string  | yes      | The commit SHA          |
| `note`       | string  | yes      | Text of comment         |
| `path`       | string  | no       | The file path           |
| `line`       | integer | no       | The line number         |
| `line_type`  | string  | no       | The line type; one of: `new`, `old` |

```
curl -X POST -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/repository/commits/6104942438c14ec7bd21c6cd5bd995272b3faff6/comments" -F "note=text1" -F "path=example.rb" -F "line=5" -F line_type=new"
```

```json
{
  "author": {
    "id": 1,
    "username": "admin",
    "email": "admin@local.host",
    "name": "Administrator",
    "blocked": false,
    "created_at": "2012-04-29T08:46:00Z"
  },
  "note": "text1",
  "path": "example.rb",
  "line": 5,
  "line_type": "new"
}
```

## Get the status of a commit

Get the statuses of a commit in a project.

```
GET /projects/:id/repository/commits/:sha/statuses
```

| Attribute  | Type    | required | Description             |
|------------|---------|----------|-------------------------|
| `id`       | integer | yes      | The ID of a project     |
| `sha`      | string  | yes      | The commit SHA          |
| `ref`      | string  | no       | Filter by ref name, it can be branch or tag |
| `stage`    | string  | no       | Filter by stage         |
| `name`     | string  | no       | Filter by status name, eg. jenkins |
| `all`      | boolean | no       | The flag to return all statuses, not only latest ones |

```
curl -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/repository/commits/6104942438c14ec7bd21c6cd5bd995272b3faff6/statuses?ref=test&name=ci%2Fjenkins"
```

```json
[
  {
    "id": 13,
    "sha": "b0b3a907f41409829b307a28b82fdbd552ee5a27",
    "ref": "test",
    "status": "success",
    "name": "ci/jenkins",
    "target_url": "http://jenkins/project/url",
    "description": "Jenkins success",
    "created_at": "2015-10-12T09:47:16.250Z",
    "started_at": "2015-10-12T09:47:16.250Z",
    "finished_at": "2015-10-12T09:47:16.262Z",
    "author": {
      "id": 1,
      "username": "admin",
      "email": "admin@local.host",
      "name": "Administrator",
      "blocked": false,
      "created_at": "2012-04-29T08:46:00Z"
    }
  }
]
```

## Post the status to commit

Adds or updates a status of a commit.

```
POST /projects/:id/statuses/:sha
```

| Attribute     | Type    | required | Description             |
|---------------|---------|----------|-------------------------|
| `id`          | integer | yes      | The ID of a project     |
| `sha`         | string  | yes      | The commit SHA          |
| `state`       | string  | yes      | The state of the status. Can be: `pending`, `running`, `success`, `failed`, `canceled` |
| `ref`         | string  | no       | The ref (branch or tag) to which the status refers |
| `name`        | string  | no       | The label to differentiate this status from the status of other systems. Default: "default". Duplicate of `context` |
| `context`     | string  | no       | The label to differentiate this status from the status of other systems. Default: "default". Duplicate of `name` |
| `target_url`  | string  | no       | The target URL to associate with this status |
| `description` | string  | no       | The short description of the status |

```
curl -X POST -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/statuses/b0b3a907f41409829b307a28b82fdbd552ee5a27" -F "state=success" -F "ref=test" -F "name=ci/jenkins" -F "target_url=http://jenkins/project/url" -F "description=Jenkins success"
```

```json
{
  "id": 13,
  "sha": "b0b3a907f41409829b307a28b82fdbd552ee5a27",
  "ref": "test",
  "status": "success",
  "name": "ci/jenkins",
  "target_url": "http://jenkins/project/url",
  "description": "Jenkins success",
  "created_at": "2015-10-12T09:47:16.250Z",
  "started_at": "2015-10-12T09:47:16.250Z",
  "finished_at": "2015-10-12T09:47:16.262Z",
  "author": {
    "id": 1,
    "username": "admin",
    "email": "admin@local.host",
    "name": "Administrator",
    "blocked": false,
    "created_at": "2012-04-29T08:46:00Z"
  }
}
```
