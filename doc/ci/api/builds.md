# Builds API

API used by runners to receive and update builds.

_**Note:** This API is intended to be used only by Runners as their own
communication channel. For the consumer API see the
[Builds API](../../api/builds.md)._

## Authentication

Unique runner token is required to authenticate. You can provide build token
using a `token` parameter, or by sending `BUILD-TOKEN` header that contains it.

`token` parameter and `BUILD-TOKEN` header can be interchangeable.

## Builds

### Runs oldest pending build by runner

    POST /builds/register

Parameters:

  * `token` (required) - The unique token of runner


### Update details of an existing build

    PUT /builds/:id

Parameters:

  * `id` (required) - The ID of a project
  * `state` (optional) - The state of a build
  * `trace` (optional) - The trace of a build

### Upload artifacts to build

    POST /builds/:id/artifacts

Parameters:

  * `id` (required) - The ID of a build
  * `token` (required) - The build authorization token
  * `file` (required) - Artifacts file

### Download the artifacts file from build

    GET /builds/:id/artifacts

Parameters:

  * `id` (required) - The ID of a build
  * `token` (required) - The build authorization token

### Remove the artifacts file from build

    DELETE /builds/:id/artifacts

Parameters:

  * ` id` (required) - The ID of a build
  * `token` (required) - The build authorization token
