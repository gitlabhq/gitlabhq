# Builds API

API used by runners to receive and update builds.

_**Note:** This API is intended to be used only by Runners as their own
communication channel. For the consumer API see the
[Builds API](../../api/builds.md)._

## Authentication

This API uses two types of authentication:

1.   Unique runner's token

     Token assigned to runner after it has been registered.

2.   Using build authorization token

     This is project's CI token that can be found in Continuous Integration
     project settings.

     Build authorization token can be passed as a parameter or a value of
     `BUILD-TOKEN` header. This method are interchangeable.

## Builds

### Runs oldest pending build by runner

    POST /ci/api/v1/builds/register

Parameters:

  * `token` (required) - Unique runner token


### Update details of an existing build

    PUT /ci/api/v1/builds/:id

Parameters:

  * `id` (required) - The ID of a project
  * `token` (required) - Unique runner token
  * `state` (optional) - The state of a build
  * `trace` (optional) - The trace of a build

### Upload artifacts to build

    POST /ci/api/v1/builds/:id/artifacts

Parameters:

  * `id` (required) - The ID of a build
  * `token` (required) - The build authorization token
  * `file` (required) - Artifacts file

### Download the artifacts file from build

    GET /ci/api/v1/builds/:id/artifacts

Parameters:

  * `id` (required) - The ID of a build
  * `token` (required) - The build authorization token

### Remove the artifacts file from build

    DELETE /ci/api/v1/builds/:id/artifacts

Parameters:

  * ` id` (required) - The ID of a build
  * `token` (required) - The build authorization token
