# Commits API

__Authentication is done by GitLab CI project token__

## Commits

### Retrieve all commits per project

Get list of commits per project

    GET /ci/commits

Parameters:

  * `project_id` (required) - The ID of a project
  * `project_token` (requires) - Project token
  * `page` (optional)
  * `per_page` (optional) - items per request (default is 20)

Returns:

```json
[{
  "id": 3,
  "ref": "master",
  "sha": "65617dfc36761baa1f46a7006f2a88916f7f56cf",
  "project_id": 2,
  "before_sha": "96906f2bceb04c7323f8514aa5ad8cb1313e2898",
  "created_at": "2014-11-05T09:46:35.247Z",
  "status": "success",
  "finished_at": "2014-11-05T09:46:44.254Z",
  "duration": 5.062692165374756,
  "git_commit_message": "wow\n",
  "git_author_name": "Administrator",
  "git_author_email": "admin@example.com",
  "builds": [{
    "id": 7,
    "project_id": 2,
    "ref": "master",
    "status": "success",
    "finished_at": "2014-11-05T09:46:44.254Z",
    "created_at": "2014-11-05T09:46:35.259Z",
    "updated_at": "2014-11-05T09:46:44.255Z",
    "sha": "65617dfc36761baa1f46a7006f2a88916f7f56cf",
    "started_at": "2014-11-05T09:46:39.192Z",
    "before_sha": "96906f2bceb04c7323f8514aa5ad8cb1313e2898",
    "runner_id": 1,
    "coverage": null,
    "commit_id": 3
  }]
}]
```

### Create commit

Inform GitLab CI about new commit you want it to build.

__If commit already exists in GitLab CI it will not be created__


    POST /ci/commits

Parameters:

  * `project_id` (required) - The ID of a project
  * `project_token` (requires) - Project token
  * `data` (required) -  Push data. For example see comment in `lib/api/commits.rb`

Returns:

```json
{
  "id": 3,
  "ref": "master",
  "sha": "65617dfc36761baa1f46a7006f2a88916f7f56cf",
  "project_id": 2,
  "before_sha": "96906f2bceb04c7323f8514aa5ad8cb1313e2898",
  "created_at": "2014-11-05T09:46:35.247Z",
  "status": "success",
  "finished_at": "2014-11-05T09:46:44.254Z",
  "duration": 5.062692165374756,
  "git_commit_message": "wow\n",
  "git_author_name": "Administrator",
  "git_author_email": "admin@example.com",
  "builds": [{
    "id": 7,
    "project_id": 2,
    "ref": "master",
    "status": "success",
    "finished_at": "2014-11-05T09:46:44.254Z",
    "created_at": "2014-11-05T09:46:35.259Z",
    "updated_at": "2014-11-05T09:46:44.255Z",
    "sha": "65617dfc36761baa1f46a7006f2a88916f7f56cf",
    "started_at": "2014-11-05T09:46:39.192Z",
    "before_sha": "96906f2bceb04c7323f8514aa5ad8cb1313e2898",
    "runner_id": 1,
    "coverage": null,
    "commit_id": 3
  }]
}
```
