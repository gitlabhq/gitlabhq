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
  "id": 48584,
  "ref": "0.1.1",
  "tag": true,
  "sha": "d63117656af6ff57d99e50cc270f854691f335ad",
  "status": "success",
  "name": "pages",
  "token": "9dd60b4f1a439d1765357446c1084c",
  "stage": "test",
  "project_id": 479,
  "project_name": "test",
  "commands": "echo commands",
  "repo_url": "http://gitlab-ci-token:token@gitlab.example/group/test.git",
  "before_sha": "0000000000000000000000000000000000000000",
  "allow_git_fetch": false,
  "options": {
    "image": "docker:image",
    "artifacts": {
      "paths": [
        "public"
      ]
    },
    "cache": {
      "paths": [
        "vendor"
      ]
    }
  },
  "timeout": 3600,
  "variables": [
    {
      "key": "CI_BUILD_TAG",
      "value": "0.1.1",
      "public": true
    }
  ],
  "depends_on_builds": [
    {
      "id": 48584,
      "ref": "0.1.1",
      "tag": true,
      "sha": "d63117656af6ff57d99e50cc270f854691f335ad",
      "status": "success",
      "name": "build",
      "token": "9dd60b4f1a439d1765357446c1084c",
      "stage": "build",
      "project_id": 479,
      "project_name": "test",
      "artifacts_file": {
        "filename": "artifacts.zip",
        "size": 0
      }
    }
  ]
}
```

### Update details of an existing build

    PUT /ci/builds/:id

Parameters:

  * `id` (required) - The ID of a project
  * `state` (optional) - The state of a build
  * `trace` (optional) - The trace of a build
