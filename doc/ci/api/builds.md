# Builds API

This API used by runners to receive and update builds.

__Authentication is done by runner token__

## Builds

### Runs oldest pending build by runner

    POST /ci/builds/register

Parameters:

  * `token` (required) - The unique token of runner

Returns:

```json
{
  "id" : 79,
  "commands" : "",
  "path" : "",
  "ref" : "",
  "sha" : "",
  "project_id" : 6,
  "repo_url" : "git@demo.gitlab.com:gitlab/gitlab-shell.git",
  "before_sha" : ""
}
```


### Update details of an existing build

    PUT /ci/builds/:id

Parameters:

  * `id` (required) - The ID of a project
  * `state` (optional) - The state of a build
  * `trace` (optional) - The trace of a build
