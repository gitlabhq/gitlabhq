# Projects API

This API is intended to aid in the setup and configuration of
projects on GitLab CI.

__Authentication is done by GitLab user token & GitLab url__

## Projects

### List Authorized Projects

Lists all projects that the authenticated user has access to.

```
GET /ci/projects
```

Returns:

```json
    [
  {
    "id" : 271,
    "name" : "gitlabhq",
    "timeout" : 1800,
    "token" : "iPWx6WM4lhHNedGfBpPJNP",
    "default_ref" : "master",
    "gitlab_url" : "http://demo.gitlabhq.com/gitlab/gitlab-shell",
    "path" : "gitlab/gitlab-shell",
    "always_build" : false,
    "polling_interval" : null,
    "public" : false,
    "ssh_url_to_repo" : "git@demo.gitlab.com:gitlab/gitlab-shell.git",
    "gitlab_id" : 3
  },
  {
    "id" : 272,
    "name" : "gitlab-ci",
    "timeout" : 1800,
    "token" : "iPWx6WM4lhHNedGfBpPJNP",
    "default_ref" : "master",
    "gitlab_url" : "http://demo.gitlabhq.com/gitlab/gitlab-shell",
    "path" : "gitlab/gitlab-shell",
    "always_build" : false,
    "polling_interval" : null,
    "public" : false,
    "ssh_url_to_repo" : "git@demo.gitlab.com:gitlab/gitlab-shell.git",
    "gitlab_id" : 4
  }
]
```

### List Owned Projects

Lists all projects that the authenticated user owns.

```
GET /ci/projects/owned
```

Returns:

```json
[
  {
    "id" : 272,
    "name" : "gitlab-ci",
    "timeout" : 1800,
    "token" : "iPWx6WM4lhHNedGfBpPJNP",
    "default_ref" : "master",
    "gitlab_url" : "http://demo.gitlabhq.com/gitlab/gitlab-shell",
    "path" : "gitlab/gitlab-shell",
    "always_build" : false,
    "polling_interval" : null,
    "public" : false,
    "ssh_url_to_repo" : "git@demo.gitlab.com:gitlab/gitlab-shell.git",
    "gitlab_id" : 4
  }
]
```

### Single Project

Returns information about a single project for which the user is
authorized.

    GET /ci/projects/:id

Parameters:

  * `id` (required) - The ID of the GitLab CI project

### Create Project

Creates a GitLab CI project using GitLab project details.

    POST /ci/projects

Parameters:

  * `name` (required) - The name of the project
  * `gitlab_id` (required) - The ID of the project on the GitLab instance
  * `default_ref` (optional) - The branch to run on (default to `master`)

### Update Project

Updates a GitLab CI project using GitLab project details that the
authenticated user has access to.

    PUT /ci/projects/:id

Parameters:

  * `name` - The name of the project
  * `default_ref` - The branch to run on (default to `master`)

### Remove Project

Removes a GitLab CI project that the authenticated user has access to.

    DELETE /ci/projects/:id

Parameters:

  * `id` (required) - The ID of the GitLab CI project

### Link Project to Runner

Links a runner to a project so that it can make builds (only via
authorized user).

    POST /ci/projects/:id/runners/:runner_id

Parameters:

  * `id` (required) - The ID of the GitLab CI project
  * `runner_id` (required) - The ID of the GitLab CI runner

### Remove Project from Runner

Removes a runner from a project so that it can not make builds (only
via authorized user).

    DELETE /ci/projects/:id/runners/:runner_id

Parameters:

  * `id` (required) - The ID of the GitLab CI project
  * `runner_id` (required) - The ID of the GitLab CI runner